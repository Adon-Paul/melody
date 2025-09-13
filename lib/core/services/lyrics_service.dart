import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_ytmusic_api/yt_music.dart';
import 'package:http/http.dart' as http;

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

// LRCLIB API Provider - High-quality synced lyrics
class LrclibProvider implements LyricsProvider {
  static const String _baseUrl = 'https://lrclib.net/api';
  
  @override
  String get name => 'LRCLIB';

  @override
  Future<LyricsData?> fetchLyrics(String artist, String title) async {
    try {
      debugPrint('🎵 LRCLIB: Searching for lyrics: $artist - $title');
      
      // Step 1: Search for track with exact match
      final searchUrl = Uri.parse('$_baseUrl/search').replace(
        queryParameters: {
          'artist_name': artist,
          'track_name': title,
        },
      );

      debugPrint('🔍 LRCLIB: Making search request');
      
      final searchResponse = await http.get(
        searchUrl,
        headers: {
          'User-Agent': 'Melody Music Player (https://github.com/nobodyuwouldknow/melody)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (searchResponse.statusCode != 200) {
        debugPrint('❌ LRCLIB: Search failed with status ${searchResponse.statusCode}');
        return null;
      }

      final List<dynamic> searchResults = json.decode(searchResponse.body);
      
      if (searchResults.isEmpty) {
        debugPrint('❌ LRCLIB: No results found');
        return null;
      }

      // Find best match
      final bestMatch = searchResults.first; // LRCLIB typically returns best matches first
      final trackId = bestMatch['id'];
      final foundTrack = bestMatch['trackName'] ?? '';
      final foundArtist = bestMatch['artistName'] ?? '';
      
      debugPrint('✅ LRCLIB: Found match: "$foundArtist - $foundTrack" (ID: $trackId)');

      // Step 2: Get detailed lyrics by ID
      final lyricsUrl = Uri.parse('$_baseUrl/get/$trackId');
      
      final lyricsResponse = await http.get(
        lyricsUrl,
        headers: {
          'User-Agent': 'Melody Music Player (https://github.com/nobodyuwouldknow/melody)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (lyricsResponse.statusCode != 200) {
        debugPrint('❌ LRCLIB: Lyrics fetch failed with status ${lyricsResponse.statusCode}');
        return null;
      }

      final lyricsData = json.decode(lyricsResponse.body);
      
      // Check for synced lyrics first
      final syncedLyrics = lyricsData['syncedLyrics'] as String?;
      final plainLyrics = lyricsData['plainLyrics'] as String?;
      final instrumental = lyricsData['instrumental'] as bool? ?? false;
      
      if (instrumental) {
        debugPrint('🎵 LRCLIB: Track is marked as instrumental');
        return LyricsData(
          songTitle: foundTrack,
          artist: foundArtist,
          lines: [LyricsLine(timestamp: 0.0, text: '[Instrumental]')],
          source: 'LRCLIB (Instrumental)',
          fetchedAt: DateTime.now(),
          isTimeSynced: false,
        );
      }

      if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
        debugPrint('✅ LRCLIB: Found synced lyrics with real timestamps');
        final lines = _parseSyncedLyrics(syncedLyrics);
        return LyricsData(
          songTitle: foundTrack,
          artist: foundArtist,
          lines: lines,
          source: 'LRCLIB (Synced)',
          fetchedAt: DateTime.now(),
          isTimeSynced: true,
        );
      } else if (plainLyrics != null && plainLyrics.isNotEmpty) {
        debugPrint('✅ LRCLIB: Found plain lyrics');
        final lines = _parsePlainLyrics(plainLyrics);
        return LyricsData(
          songTitle: foundTrack,
          artist: foundArtist,
          lines: lines,
          source: 'LRCLIB (Plain)',
          fetchedAt: DateTime.now(),
          isTimeSynced: false,
        );
      }

      debugPrint('❌ LRCLIB: No lyrics available');
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ LRCLIB: Exception - $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  // Parse synced lyrics (LRC format) - Real timestamps from LRCLIB
  List<LyricsLine> _parseSyncedLyrics(String syncedLyrics) {
    List<LyricsLine> lines = [];
    
    try {
      final lrcLines = syncedLyrics.split('\n');
      
      for (final line in lrcLines) {
        final trimmedLine = line.trim();
        if (trimmedLine.isEmpty) continue;
        
        // Parse LRC format: [mm:ss.xx]text or [mm:ss.xxx]text
        final lrcRegex = RegExp(r'\[(\d{1,2}):(\d{2})[\.:](\d{2,3})\](.*)');
        final match = lrcRegex.firstMatch(trimmedLine);
        
        if (match != null) {
          final minutes = int.parse(match.group(1) ?? '0');
          final seconds = int.parse(match.group(2) ?? '0');
          final millisStr = match.group(3) ?? '0';
          final text = (match.group(4) ?? '').trim();
          
          // Handle both .xx and .xxx formats
          final millis = millisStr.length == 2 
              ? int.parse(millisStr) * 10  // .xx format (centiseconds)
              : int.parse(millisStr);      // .xxx format (milliseconds)
          
          final timestamp = minutes * 60.0 + seconds + millis / 1000.0;
          
          if (text.isNotEmpty) {
            lines.add(LyricsLine(
              timestamp: timestamp,
              text: text,
              isChorus: text.toLowerCase().contains('chorus'),
              isVerse: text.toLowerCase().contains('verse'),
            ));
          }
        }
      }
      
      debugPrint('✅ LRCLIB: Parsed ${lines.length} synced lyrics lines with real timestamps');
      return lines;
    } catch (e) {
      debugPrint('❌ LRCLIB: Error parsing synced lyrics - $e');
      return [];
    }
  }

  // Parse plain text lyrics
  List<LyricsLine> _parsePlainLyrics(String plainLyrics) {
    final lines = plainLyrics.split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();

    List<LyricsLine> lyricsLines = [];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isNotEmpty) {
        lyricsLines.add(LyricsLine(
          timestamp: i * 3.5, // Estimate 3.5 seconds per line
          text: line,
          isChorus: line.toLowerCase().contains('chorus'),
          isVerse: line.toLowerCase().contains('verse'),
        ));
      }
    }
    
    debugPrint('✅ LRCLIB: Parsed ${lyricsLines.length} plain lyrics lines');
    return lyricsLines;
  }
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
    LrclibProvider(),        // Primary provider - high quality synced lyrics
    MusixmatchProvider(),    // Fallback with fuzzy matching
    YouTubeMusicProvider(),  // Fallback for variety
    GeniusProvider(),        // Fallback for rare tracks
    LyricFindProvider(),     // Last resort
  ];

  LyricsData? _currentLyrics;
  int _currentLineIndex = -1;
  bool _isEnabled = true;
  bool _isLoading = false;
  String? _error;
  
  // Settings
  bool _autoScroll = true;
  double _fontSize = 20.0;
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
    await _loadProviderSettings();
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

      // Try each enabled provider until we get lyrics
      for (final provider in _providers) {
        // Skip disabled providers
        if (!_enabledProviders.contains(provider.name)) {
          continue;
        }
        
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
      _fontSize = prefs.getDouble('lyrics_font_size') ?? 20.0;
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

  // Provider Management Methods
  String _primaryProvider = 'LRCLIB';
  Set<String> _enabledProviders = {'LRCLIB', 'YouTube Music', 'Musixmatch'};

  String get primaryProvider => _primaryProvider;
  
  List<String> get availableProviders => _providers.map((p) => p.name).toList();
  
  Set<String> get enabledProviders => Set.from(_enabledProviders);

  Future<void> setPrimaryProvider(String providerName) async {
    if (availableProviders.contains(providerName)) {
      _primaryProvider = providerName;
      
      // Reorder providers to put primary first
      _reorderProviders();
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('lyrics_primary_provider', _primaryProvider);
      
      notifyListeners();
    }
  }

  Future<void> toggleProvider(String providerName) async {
    if (availableProviders.contains(providerName)) {
      if (_enabledProviders.contains(providerName)) {
        // Don't allow disabling if it's the only enabled provider
        if (_enabledProviders.length > 1) {
          _enabledProviders.remove(providerName);
        }
      } else {
        _enabledProviders.add(providerName);
      }
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('lyrics_enabled_providers', _enabledProviders.toList());
      
      notifyListeners();
    }
  }

  void _reorderProviders() {
    // Find the primary provider and move it to the front
    final primaryProviderIndex = _providers.indexWhere((p) => p.name == _primaryProvider);
    if (primaryProviderIndex > 0) {
      final primaryProvider = _providers.removeAt(primaryProviderIndex);
      _providers.insert(0, primaryProvider);
    }
  }

  Future<void> _loadProviderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _primaryProvider = prefs.getString('lyrics_primary_provider') ?? 'LRCLIB';
      
      final enabledList = prefs.getStringList('lyrics_enabled_providers');
      if (enabledList != null && enabledList.isNotEmpty) {
        _enabledProviders = enabledList.toSet();
      }
      
      // Ensure primary provider is enabled
      _enabledProviders.add(_primaryProvider);
      
      // Reorder providers based on primary selection
      _reorderProviders();
    } catch (e) {
      debugPrint('Provider settings load error: $e');
    }
  }
}
