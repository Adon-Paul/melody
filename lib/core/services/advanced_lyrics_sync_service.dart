import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:lrc/lrc.dart';

/// Advanced lyrics synchronization service with word-perfect timing
class AdvancedLyricsSyncService extends ChangeNotifier {
  static final AdvancedLyricsSyncService _instance = AdvancedLyricsSyncService._internal();
  factory AdvancedLyricsSyncService() => _instance;
  AdvancedLyricsSyncService._internal();

  // Core state
  StreamSubscription<LrcStream>? _lyricsSubscription;
  Lrc? _currentLrc;
  LrcLine? _currentLine;
  LrcLine? _nextLine;
  LrcLine? _previousLine;
  int _currentLineIndex = -1;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  
  // Settings
  bool _isEnabled = true;
  bool _autoScroll = true;
  double _fontSize = 16.0;
  double _syncOffset = 0.0; // Offset in milliseconds for fine-tuning

  // Getters
  Lrc? get currentLrc => _currentLrc;
  LrcLine? get currentLine => _currentLine;
  LrcLine? get nextLine => _nextLine;
  LrcLine? get previousLine => _previousLine;
  int get currentLineIndex => _currentLineIndex;
  bool get isEnabled => _isEnabled;
  bool get isPlaying => _isPlaying;
  bool get autoScroll => _autoScroll;
  double get fontSize => _fontSize;
  double get syncOffset => _syncOffset;
  List<LrcLine> get allLines => _currentLrc?.lyrics ?? [];
  bool get hasLyrics => _currentLrc != null && allLines.isNotEmpty;

  Future<void> initialize() async {
    await _loadSettings();
  }

  /// Load lyrics from LRCLIB API with high precision timing
  Future<void> loadLyrics(String artist, String title) async {
    try {
      debugPrint('🎵 Advanced Sync: Loading lyrics for $artist - $title');
      
      // Try to get from cache first
      final cachedLrc = await _getCachedLrc(artist, title);
      if (cachedLrc != null) {
        await _setCurrentLrc(cachedLrc);
        return;
      }

      // Fetch from LRCLIB API
      final lrcString = await _fetchLrcFromAPI(artist, title);
      if (lrcString != null && lrcString.isNotEmpty) {
        if (lrcString.isValidLrc) {
          final lrc = Lrc.parse(lrcString);
          await _setCurrentLrc(lrc);
          await _cacheLrc(artist, title, lrcString);
        } else {
          debugPrint('❌ Invalid LRC format received');
          _clearLyrics();
        }
      } else {
        debugPrint('❌ No lyrics found');
        _clearLyrics();
      }
    } catch (e) {
      debugPrint('❌ Error loading lyrics: $e');
      _clearLyrics();
    }
  }

  /// Fetch LRC formatted lyrics from LRCLIB API
  Future<String?> _fetchLrcFromAPI(String artist, String title) async {
    int retryCount = 0;
    const maxRetries = 2;
    
    while (retryCount <= maxRetries) {
      try {
        // Search for track with reduced timeout
        final searchUrl = Uri.parse('https://lrclib.net/api/search').replace(
          queryParameters: {
            'artist_name': artist,
            'track_name': title,
          },
        );

        debugPrint('🔍 Fetching lyrics (attempt ${retryCount + 1}/${maxRetries + 1}) for: $artist - $title');

        final searchResponse = await http.get(
          searchUrl,
          headers: {
            'User-Agent': 'Melody Music Player (Advanced Sync)',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 8)); // Reduced from 10 to 8 seconds

        if (searchResponse.statusCode != 200) {
          debugPrint('❌ Search failed with status: ${searchResponse.statusCode}');
          if (retryCount < maxRetries) {
            retryCount++;
            await Future.delayed(Duration(seconds: retryCount)); // Progressive delay
            continue;
          }
          return null;
        }

        final List<dynamic> searchResults = json.decode(searchResponse.body);
        if (searchResults.isEmpty) {
          debugPrint('❌ No search results found');
          return null;
        }

        // Get best match
        final bestMatch = searchResults.first;
        final trackId = bestMatch['id'];

        // Get detailed lyrics with shorter timeout
        final lyricsUrl = Uri.parse('https://lrclib.net/api/get/$trackId');
        final lyricsResponse = await http.get(
          lyricsUrl,
          headers: {
            'User-Agent': 'Melody Music Player (Advanced Sync)',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 6)); // Reduced from 10 to 6 seconds

        if (lyricsResponse.statusCode != 200) {
          debugPrint('❌ Lyrics fetch failed with status: ${lyricsResponse.statusCode}');
          if (retryCount < maxRetries) {
            retryCount++;
            await Future.delayed(Duration(seconds: retryCount));
            continue;
          }
          return null;
        }

        final lyricsData = json.decode(lyricsResponse.body);
        final syncedLyrics = lyricsData['syncedLyrics'] as String?;
        
        if (syncedLyrics != null && syncedLyrics.isNotEmpty) {
          debugPrint('✅ Advanced Sync: Found synced LRC lyrics');
          return syncedLyrics;
        }

        // Fall back to plain lyrics if no synced version
        final plainLyrics = lyricsData['plainLyrics'] as String?;
        if (plainLyrics != null && plainLyrics.isNotEmpty) {
          debugPrint('⚠️ Advanced Sync: Using plain lyrics (no sync)');
          return _convertPlainToLrc(plainLyrics);
        }

        return null;
      } on TimeoutException catch (e) {
        debugPrint('⏱️ API timeout (attempt ${retryCount + 1}): $e');
        if (retryCount < maxRetries) {
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount * 2)); // Longer delay for timeouts
          continue;
        }
        debugPrint('❌ API timeout: All retry attempts failed');
        return null;
      } catch (e) {
        debugPrint('❌ API fetch error (attempt ${retryCount + 1}): $e');
        if (retryCount < maxRetries && !e.toString().contains('SocketException')) {
          retryCount++;
          await Future.delayed(Duration(seconds: retryCount));
          continue;
        }
        return null;
      }
    }
    
    return null;
  }

  /// Convert plain text lyrics to estimated LRC format
  String _convertPlainToLrc(String plainLyrics) {
    final lines = plainLyrics.split('\n').where((line) => line.trim().isNotEmpty).toList();
    final lrcLines = <String>[];
    
    for (int i = 0; i < lines.length; i++) {
      // Estimate timing: 4 seconds per line
      final seconds = i * 4;
      final minutes = seconds ~/ 60;
      final remainingSeconds = seconds % 60;
      
      lrcLines.add('[${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}.00]${lines[i].trim()}');
    }
    
    return lrcLines.join('\n');
  }

  /// Set current LRC and reset sync state
  Future<void> _setCurrentLrc(Lrc lrc) async {
    _currentLrc = lrc;
    _currentLine = null;
    _nextLine = null;
    _previousLine = null;
    _currentLineIndex = -1;
    
    debugPrint('✅ Advanced Sync: Loaded ${lrc.lyrics.length} lyrics lines');
    notifyListeners();
  }

  /// Clear all lyrics and stop sync
  void _clearLyrics() {
    _stopSync();
    _currentLrc = null;
    _currentLine = null;
    _nextLine = null;
    _previousLine = null;
    _currentLineIndex = -1;
    notifyListeners();
  }

  /// Start precise lyrics synchronization
  void startSync() {
    if (!_isEnabled || _currentLrc == null || _currentLrc!.lyrics.isEmpty) {
      return;
    }

    _stopSync(); // Stop any existing sync
    _isPlaying = true;

    debugPrint('🎵 Advanced Sync: Starting word-perfect synchronization');

    // Create adjusted lyrics with offset
    final adjustedLines = _currentLrc!.lyrics.map((line) {
      final adjustedTimestamp = Duration(
        milliseconds: line.timestamp.inMilliseconds + _syncOffset.round()
      );
      return LrcLine(
        timestamp: adjustedTimestamp,
        lyrics: line.lyrics,
        type: line.type,
        args: line.args,
      );
    }).toList();

    // Start streaming with precise timing
    _lyricsSubscription = adjustedLines.toStream().listen(
      (LrcStream stream) {
        _updateCurrentLine(stream);
      },
      onError: (error) {
        debugPrint('❌ Sync stream error: $error');
      },
      onDone: () {
        debugPrint('✅ Sync stream completed');
        _isPlaying = false;
        notifyListeners();
      },
    );

    notifyListeners();
  }

  /// Stop lyrics synchronization
  void _stopSync() {
    _lyricsSubscription?.cancel();
    _lyricsSubscription = null;
    _isPlaying = false;
  }

  /// Update current line from stream
  void _updateCurrentLine(LrcStream stream) {
    _previousLine = stream.previous;
    _currentLine = stream.current;
    _nextLine = stream.next;
    _currentLineIndex = stream.position;

    debugPrint('🎵 Sync: Line ${stream.position + 1}/${stream.length} - "${stream.current.lyrics}"');
    notifyListeners();
  }

  /// Manually sync to specific position (for seeking)
  void syncToPosition(Duration position) {
    if (_currentLrc == null || _currentLrc!.lyrics.isEmpty) {
      return;
    }

    _currentPosition = position;
    final positionSeconds = position.inMilliseconds / 1000.0;

    // Find the correct line for this position
    int lineIndex = -1;
    for (int i = 0; i < _currentLrc!.lyrics.length; i++) {
      final lineTime = _currentLrc!.lyrics[i].timestamp.inMilliseconds / 1000.0;
      if (lineTime <= positionSeconds) {
        lineIndex = i;
      } else {
        break;
      }
    }

    // Update current line state
    _currentLineIndex = lineIndex;
    
    if (lineIndex >= 0) {
      _currentLine = _currentLrc!.lyrics[lineIndex];
      _previousLine = lineIndex > 0 ? _currentLrc!.lyrics[lineIndex - 1] : null;
      _nextLine = lineIndex < _currentLrc!.lyrics.length - 1 ? _currentLrc!.lyrics[lineIndex + 1] : null;
    } else {
      _currentLine = null;
      _previousLine = null;
      _nextLine = _currentLrc!.lyrics.isNotEmpty ? _currentLrc!.lyrics[0] : null;
    }

    debugPrint('🎵 Manual Sync: Position ${position.inSeconds}s -> Line ${lineIndex + 1}');
    notifyListeners();
  }

  /// Stop lyrics sync
  void stopSync() {
    _stopSync();
    _isPlaying = false;
    notifyListeners();
  }

  /// Pause lyrics sync
  void pauseSync() {
    _stopSync();
    _isPlaying = false;
    notifyListeners();
  }

  /// Resume lyrics sync from current position
  void resumeSync() {
    if (_currentPosition != Duration.zero) {
      syncToPosition(_currentPosition);
    }
    startSync();
  }

  /// Settings management
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    if (!enabled) {
      stopSync();
    }
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setAutoScroll(bool autoScroll) async {
    _autoScroll = autoScroll;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setFontSize(double fontSize) async {
    _fontSize = fontSize.clamp(12.0, 24.0);
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setSyncOffset(double offsetMs) async {
    _syncOffset = offsetMs.clamp(-5000.0, 5000.0);
    await _saveSettings();
    notifyListeners();
  }

  /// Cache management
  Future<void> _cacheLrc(String artist, String title, String lrcString) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'advanced_lrc_${_getCacheKey(artist, title)}';
      await prefs.setString(key, lrcString);
    } catch (e) {
      debugPrint('Cache write error: $e');
    }
  }

  Future<Lrc?> _getCachedLrc(String artist, String title) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'advanced_lrc_${_getCacheKey(artist, title)}';
      final lrcString = prefs.getString(key);
      
      if (lrcString != null && lrcString.isValidLrc) {
        return Lrc.parse(lrcString);
      }
    } catch (e) {
      debugPrint('Cache read error: $e');
    }
    return null;
  }

  String _getCacheKey(String artist, String title) {
    final input = '${artist.toLowerCase().trim()}_${title.toLowerCase().trim()}';
    return input.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(' ', '_');
  }

  /// Settings persistence
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('advanced_lyrics_enabled') ?? true;
      _autoScroll = prefs.getBool('advanced_lyrics_auto_scroll') ?? true;
      _fontSize = prefs.getDouble('advanced_lyrics_font_size') ?? 16.0;
      _syncOffset = prefs.getDouble('advanced_lyrics_sync_offset') ?? 0.0;
    } catch (e) {
      debugPrint('Settings load error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('advanced_lyrics_enabled', _isEnabled);
      await prefs.setBool('advanced_lyrics_auto_scroll', _autoScroll);
      await prefs.setDouble('advanced_lyrics_font_size', _fontSize);
      await prefs.setDouble('advanced_lyrics_sync_offset', _syncOffset);
    } catch (e) {
      debugPrint('Settings save error: $e');
    }
  }

  /// Adjust lyrics sync delay by specified milliseconds
  void adjustDelay(double deltaMs) {
    _syncOffset += deltaMs;
    _saveSettings();
    notifyListeners();
  }

  /// Reset lyrics sync delay to zero
  void resetDelay() {
    _syncOffset = 0.0;
    _saveSettings();
    notifyListeners();
  }

  /// Get current delay in milliseconds
  double getDelay() {
    return _syncOffset;
  }

  /// Clean up resources
  @override
  void dispose() {
    _stopSync();
    super.dispose();
  }
}
