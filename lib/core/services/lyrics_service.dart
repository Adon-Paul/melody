import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_ytmusic_api/yt_music.dart';

class LyricsLine {
  final double timestamp; // in seconds
  final String text;
  final bool isChorus;
  final bool isVerse;

  LyricsLine({
    required this.timestamp,
    required this.text,
    this.isChorus = false,
    this.isVerse = false,
  });

  factory LyricsLine.fromJson(Map<String, dynamic> json) {
    return LyricsLine(
      timestamp: (json['timestamp'] as num).toDouble(),
      text: json['text'] as String,
      isChorus: json['isChorus'] as bool? ?? false,
      isVerse: json['isVerse'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp,
      'text': text,
      'isChorus': isChorus,
      'isVerse': isVerse,
    };
  }
}

class LyricsData {
  final String songTitle;
  final String artist;
  final List<LyricsLine> lines;
  final String source;
  final DateTime fetchedAt;
  final bool isTimeSynced;

  LyricsData({
    required this.songTitle,
    required this.artist,
    required this.lines,
    required this.source,
    required this.fetchedAt,
    required this.isTimeSynced,
  });

  factory LyricsData.fromJson(Map<String, dynamic> json) {
    return LyricsData(
      songTitle: json['songTitle'] as String,
      artist: json['artist'] as String,
      lines: (json['lines'] as List)
          .map((line) => LyricsLine.fromJson(line))
          .toList(),
      source: json['source'] as String,
      fetchedAt: DateTime.parse(json['fetchedAt'] as String),
      isTimeSynced: json['isTimeSynced'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'songTitle': songTitle,
      'artist': artist,
      'lines': lines.map((line) => line.toJson()).toList(),
      'source': source,
      'fetchedAt': fetchedAt.toIso8601String(),
      'isTimeSynced': isTimeSynced,
    };
  }
}

abstract class LyricsProvider {
  String get name;
  Future<LyricsData?> fetchLyrics(String artist, String title);
}

class MusixmatchProvider implements LyricsProvider {
  @override
  String get name => 'Musixmatch';

  @override
  Future<LyricsData?> fetchLyrics(String artist, String title) async {
    try {
      // Note: This would need proper Musixmatch API implementation
      // For now, return null to let YouTube Music handle it
      debugPrint('Musixmatch provider not implemented, skipping: $artist - $title');
      return null;
    } catch (e) {
      debugPrint('Musixmatch error: $e');
      return null;
    }
  }
}

class GeniusProvider implements LyricsProvider {
  @override
  String get name => 'Genius';

  @override
  Future<LyricsData?> fetchLyrics(String artist, String title) async {
    try {
      // Note: This would need proper Genius API implementation
      // For now, return null to let YouTube Music handle it
      debugPrint('Genius provider not implemented, skipping: $artist - $title');
      return null;
    } catch (e) {
      debugPrint('Genius error: $e');
      return null;
    }
  }
}

class YouTubeMusicProvider implements LyricsProvider {
  static YTMusic? _ytMusic;
  
  @override
  String get name => 'YouTube Music';

  Future<YTMusic> _getYTMusic() async {
    if (_ytMusic == null) {
      _ytMusic = YTMusic();
      try {
        await _ytMusic!.initialize();
      } catch (e) {
        debugPrint('YouTube Music API initialization failed: $e');
        // Continue without initialization - some methods might still work
      }
    }
    return _ytMusic!;
  }

  @override
  Future<LyricsData?> fetchLyrics(String artist, String title) async {
    try {
      debugPrint('YouTube Music: Searching for lyrics: $artist - $title');
      final ytMusic = await _getYTMusic();
      
      // Search for the song
      final query = '$artist $title';
      debugPrint('YouTube Music: Searching with query: $query');
      
      final searchResults = await ytMusic.searchSongs(query);
      debugPrint('YouTube Music: Found ${searchResults.length} search results');
      
      if (searchResults.isEmpty) {
        debugPrint('No YouTube Music results found for: $query');
        return null;
      }

      // Try to get lyrics from the first few results
      for (int i = 0; i < (searchResults.length > 3 ? 3 : searchResults.length); i++) {
        try {
          final song = searchResults[i];
          final videoId = song.videoId;
          
          debugPrint('YouTube Music: Trying song $i with videoId: $videoId');
          
          if (videoId.isEmpty) {
            debugPrint('YouTube Music: Empty video ID for result $i, skipping');
            continue;
          }
          
          // Try to get regular lyrics first
          try {
            debugPrint('YouTube Music: Attempting to get lyrics for $videoId');
            final lyrics = await ytMusic.getLyrics(videoId);
            if (lyrics != null && lyrics.isNotEmpty) {
              debugPrint('YouTube Music: Found lyrics (${lyrics.length} characters)');
              return _parseRegularLyrics(lyrics, artist, title);
            } else {
              debugPrint('YouTube Music: No lyrics found for $videoId');
            }
          } catch (e) {
            debugPrint('YouTube Music: Regular lyrics failed for $videoId: $e');
          }
          
          // Try to get timed lyrics if regular lyrics failed
          try {
            debugPrint('YouTube Music: Attempting to get timed lyrics for $videoId');
            final timedLyrics = await ytMusic.getTimedLyrics(videoId);
            if (timedLyrics != null) {
              debugPrint('YouTube Music: Found timed lyrics');
              return _parseTimedLyrics(timedLyrics, artist, title);
            } else {
              debugPrint('YouTube Music: No timed lyrics found for $videoId');
            }
          } catch (e) {
            debugPrint('YouTube Music: Timed lyrics failed for $videoId: $e');
          }
          
        } catch (e) {
          debugPrint('YouTube Music: Error processing search result $i: $e');
          continue;
        }
      }
      
      debugPrint('YouTube Music: No lyrics found in any of the search results');
      return null;
    } catch (e) {
      debugPrint('YouTube Music provider error: $e');
      return null;
    }
  }

  LyricsData _parseTimedLyrics(dynamic timedLyrics, String artist, String title) {
    final lines = <LyricsLine>[];
    
    try {
      // Extract lyrics from the timed lyrics response
      // The exact structure depends on the API response
      final lyricsText = timedLyrics.toString();
      return _parseRegularLyrics(lyricsText, artist, title);
    } catch (e) {
      debugPrint('Error parsing timed lyrics: $e');
    }
    
    return LyricsData(
      songTitle: title,
      artist: artist,
      lines: lines,
      source: 'YouTube Music (Timed)',
      fetchedAt: DateTime.now(),
      isTimeSynced: true,
    );
  }

  LyricsData _parseRegularLyrics(String lyrics, String artist, String title) {
    final lines = <LyricsLine>[];
    final lyricsLines = lyrics.split('\n');
    
    double currentTime = 0.0;
    const averageLineInterval = 4.0; // Assume 4 seconds per line
    
    for (final line in lyricsLines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty) {
        lines.add(LyricsLine(
          timestamp: currentTime,
          text: trimmedLine,
          isChorus: _isChorusLine(trimmedLine),
          isVerse: _isVerseLine(trimmedLine),
        ));
        currentTime += averageLineInterval;
      }
    }
    
    return LyricsData(
      songTitle: title,
      artist: artist,
      lines: lines,
      source: 'YouTube Music',
      fetchedAt: DateTime.now(),
      isTimeSynced: false,
    );
  }

  bool _isChorusLine(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains('chorus') || 
           lowerText.contains('hook') ||
           lowerText.contains('[chorus]') ||
           lowerText.contains('(chorus)');
  }

  bool _isVerseLine(String text) {
    final lowerText = text.toLowerCase();
    return lowerText.contains('verse') || 
           lowerText.contains('[verse') ||
           lowerText.contains('(verse');
  }
}

class LyricFindProvider implements LyricsProvider {
  @override
  String get name => 'LyricFind';

  @override
  Future<LyricsData?> fetchLyrics(String artist, String title) async {
    try {
      // Note: This would need proper LyricFind API implementation
      // For now, return null to let YouTube Music handle it
      debugPrint('LyricFind provider not implemented, skipping: $artist - $title');
      return null;
    } catch (e) {
      debugPrint('LyricFind error: $e');
      return null;
    }
  }
}

class LyricsService extends ChangeNotifier {
  static final LyricsService _instance = LyricsService._internal();
  factory LyricsService() => _instance;
  LyricsService._internal();

  final List<LyricsProvider> _providers = [
    YouTubeMusicProvider(),
    MusixmatchProvider(),
    GeniusProvider(),
    LyricFindProvider(),
  ];

  LyricsData? _currentLyrics;
  int _currentLineIndex = -1;
  bool _isEnabled = true;
  bool _isLoading = false;
  String? _error;
  
  // Settings
  bool _autoScroll = true;
  double _fontSize = 16.0;
  bool _showTimestamps = false;
  bool _highlightChorus = true;

  // Getters
  LyricsData? get currentLyrics => _currentLyrics;
  int get currentLineIndex => _currentLineIndex;
  bool get isEnabled => _isEnabled;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get autoScroll => _autoScroll;
  double get fontSize => _fontSize;
  bool get showTimestamps => _showTimestamps;
  bool get highlightChorus => _highlightChorus;

  Future<void> initialize() async {
    await _loadSettings();
  }

  Future<void> fetchLyrics(String artist, String title) async {
    if (!_isEnabled) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Check cache first
      final cachedLyrics = await _getCachedLyrics(artist, title);
      if (cachedLyrics != null) {
        _currentLyrics = cachedLyrics;
        _currentLineIndex = -1;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Try each provider until we get lyrics
      for (final provider in _providers) {
        try {
          final lyrics = await provider.fetchLyrics(artist, title);
          if (lyrics != null && lyrics.lines.isNotEmpty) {
            _currentLyrics = lyrics;
            _currentLineIndex = -1;
            await _cacheLyrics(lyrics);
            break;
          }
        } catch (e) {
          debugPrint('Provider ${provider.name} failed: $e');
          continue;
        }
      }

      if (_currentLyrics == null) {
        _error = 'No lyrics found for this song';
      }
    } catch (e) {
      _error = 'Failed to fetch lyrics: $e';
      debugPrint('Lyrics fetch error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  void updateCurrentTime(double currentSeconds) {
    if (_currentLyrics == null || _currentLyrics!.lines.isEmpty) return;

    // Find the current line based on timestamp
    int newIndex = -1;
    for (int i = 0; i < _currentLyrics!.lines.length; i++) {
      if (_currentLyrics!.lines[i].timestamp <= currentSeconds) {
        newIndex = i;
      } else {
        break;
      }
    }

    if (newIndex != _currentLineIndex) {
      _currentLineIndex = newIndex;
      notifyListeners();
    }
  }

  void clearLyrics() {
    _currentLyrics = null;
    _currentLineIndex = -1;
    _error = null;
    notifyListeners();
  }

  // Settings
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lyrics_enabled', enabled);
    notifyListeners();
  }

  Future<void> setAutoScroll(bool autoScroll) async {
    _autoScroll = autoScroll;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lyrics_auto_scroll', autoScroll);
    notifyListeners();
  }

  Future<void> setFontSize(double fontSize) async {
    _fontSize = fontSize;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('lyrics_font_size', fontSize);
    notifyListeners();
  }

  Future<void> setShowTimestamps(bool show) async {
    _showTimestamps = show;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lyrics_show_timestamps', show);
    notifyListeners();
  }

  Future<void> setHighlightChorus(bool highlight) async {
    _highlightChorus = highlight;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lyrics_highlight_chorus', highlight);
    notifyListeners();
  }

  // Cache management
  String _getCacheKey(String artist, String title) {
    final combined = '${artist.toLowerCase()}_${title.toLowerCase()}';
    return md5.convert(utf8.encode(combined)).toString();
  }

  Future<LyricsData?> _getCachedLyrics(String artist, String title) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(artist, title);
      final cachedJson = prefs.getString('lyrics_cache_$cacheKey');
      
      if (cachedJson != null) {
        final data = json.decode(cachedJson);
        final lyrics = LyricsData.fromJson(data);
        
        // Check if cache is still valid (7 days)
        final now = DateTime.now();
        if (now.difference(lyrics.fetchedAt).inDays < 7) {
          return lyrics;
        }
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }
    return null;
  }

  Future<void> _cacheLyrics(LyricsData lyrics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(lyrics.artist, lyrics.songTitle);
      final jsonString = json.encode(lyrics.toJson());
      await prefs.setString('lyrics_cache_$cacheKey', jsonString);
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('lyrics_enabled') ?? true;
      _autoScroll = prefs.getBool('lyrics_auto_scroll') ?? true;
      _fontSize = prefs.getDouble('lyrics_font_size') ?? 16.0;
      _showTimestamps = prefs.getBool('lyrics_show_timestamps') ?? false;
      _highlightChorus = prefs.getBool('lyrics_highlight_chorus') ?? true;
    } catch (e) {
      debugPrint('Settings load error: $e');
    }
  }

  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('lyrics_cache_'));
      for (final key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      debugPrint('Cache clear error: $e');
    }
  }
}
