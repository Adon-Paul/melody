import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:audio_session/audio_session.dart';
import 'dart:io';
import 'dart:typed_data';
import 'notification_service.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final String path;
  final Duration? duration;
  final Uint8List? albumArt;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.path,
    this.duration,
    this.albumArt,
  });

  static Future<Song> fromFile(File file) async {
    final fileName = file.path.split('/').last;
    final nameWithoutExtension = fileName.split('.').first;
    
    String title = nameWithoutExtension;
    String artist = 'Unknown Artist';
    Duration? duration;
    Uint8List? albumArt;
    
    try {
      // Extract metadata using audio_metadata_reader
      final metadata = readMetadata(file, getImage: true);
      
      // Extract basic info
      title = metadata.title?.isNotEmpty == true ? metadata.title! : nameWithoutExtension;
      artist = metadata.artist?.isNotEmpty == true ? metadata.artist! : 'Unknown Artist';
      duration = metadata.duration;
      
      // Extract album art
      if (metadata.pictures.isNotEmpty) {
        albumArt = metadata.pictures.first.bytes;
      }
    } catch (e) {
      debugPrint('Failed to extract metadata for ${file.path}: $e');
      // Keep default values
    }
    
    return Song(
      id: file.path,
      title: title,
      artist: artist,
      path: file.path,
      duration: duration,
      albumArt: albumArt,
    );
  }
}

class MusicService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<Song> _songs = [];
  List<Song> _playlist = [];
  Song? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 0.8;
  String? _errorMessage;
  bool _isShuffleEnabled = false;
  bool _isRepeatEnabled = false;
  bool _autoPlayNext = true; // Auto-play next song when current ends
  int _currentPlaylistIndex = 0;

  // Getters
  List<Song> get songs => _songs;
  List<Song> get playlist => _playlist;
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  double get volume => _volume;
  String? get errorMessage => _errorMessage;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isRepeatEnabled => _isRepeatEnabled;
  bool get autoPlayNext => _autoPlayNext;
  int get currentPlaylistIndex => _currentPlaylistIndex;
  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  MusicService() {
    _init();
    _initNotifications();
  }

  void _init() {
    _initAudioSession();
    
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _updateNotification();
      notifyListeners();
      
      // Handle song completion for auto-play
      if (state.processingState == ProcessingState.completed && _autoPlayNext) {
        _handleSongCompletion();
      }
    });

    // Listen to position changes
    _audioPlayer.positionStream.listen((position) {
      _position = position;
      notifyListeners();
    });

    // Listen to duration changes
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _duration = duration;
        notifyListeners();
      }
    });

    // Auto-load songs when service initializes
    loadSongs();
  }

  // Initialize notification service
  Future<void> _initNotifications() async {
    try {
      await NotificationService.initialize();
      NotificationService.setupNotificationHandlers(this);
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  // Update notification with current song info
  void _updateNotification() {
    if (_currentSong != null) {
      NotificationService.updateNotification(
        title: _currentSong!.title,
        artist: _currentSong!.artist,
        isPlaying: _isPlaying,
      );
    }
  }

  // Initialize audio session for background playback
  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e) {
      debugPrint('Failed to configure audio session: $e');
    }
  }

  // Handle what happens when a song completes
  Future<void> _handleSongCompletion() async {
    if (_isRepeatEnabled) {
      // Repeat current song
      await _audioPlayer.seek(Duration.zero);
      await _audioPlayer.play();
    } else {
      // Play next song
      await playNext();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Load songs from device storage with optimized scanning
  Future<void> loadSongs() async {
    try {
      _setLoading(true);
      _setError(null);
      
      final musicFiles = await _getMusicFiles();
      
      // First pass: Create basic songs quickly without metadata
      List<Song> quickSongs = musicFiles.map((file) {
        final fileName = file.path.split('/').last;
        final nameWithoutExtension = fileName.split('.').first;
        return Song(
          id: file.path,
          title: nameWithoutExtension,
          artist: 'Loading...',
          path: file.path,
        );
      }).toList();
      
      // Update UI immediately with basic info
      _songs = quickSongs;
      notifyListeners();
      
      // Second pass: Load metadata in background with larger batches
      List<Song> detailedSongs = [];
      const batchSize = 10; // Increased batch size for better performance
      
      for (int i = 0; i < musicFiles.length; i += batchSize) {
        final batch = musicFiles.skip(i).take(batchSize).toList();
        
        // Process batch in parallel but with timeout
        final futures = batch.map((file) => _loadSongWithTimeout(file)).toList();
        final batchSongs = await Future.wait(futures);
        
        // Update songs that loaded successfully
        for (int j = 0; j < batchSongs.length; j++) {
          final songIndex = i + j;
          if (songIndex < _songs.length && batchSongs[j] != null) {
            detailedSongs.add(batchSongs[j]!);
          } else {
            // Keep the quick song if metadata loading failed
            detailedSongs.add(quickSongs[songIndex]);
          }
        }
        
        // Update UI with new batch
        _songs = List.from(detailedSongs);
        notifyListeners();
        
        // Minimal delay to keep UI responsive
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      _songs = detailedSongs;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load music files: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Load song with timeout to prevent hanging
  Future<Song?> _loadSongWithTimeout(File file) async {
    try {
      return await Song.fromFile(file).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          // Return basic song if metadata loading times out
          final fileName = file.path.split('/').last;
          final nameWithoutExtension = fileName.split('.').first;
          return Song(
            id: file.path,
            title: nameWithoutExtension,
            artist: 'Unknown Artist',
            path: file.path,
          );
        },
      );
    } catch (e) {
      // Return basic song if any error occurs
      final fileName = file.path.split('/').last;
      final nameWithoutExtension = fileName.split('.').first;
      return Song(
        id: file.path,
        title: nameWithoutExtension,
        artist: 'Unknown Artist',
        path: file.path,
      );
    }
  }

  Future<List<File>> _getMusicFiles() async {
    final musicFiles = <File>[];
    
    if (Platform.isAndroid) {
      bool permissionGranted = false;
      
      // Check Android version for permission handling
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      
      if (sdkInt >= 30) {
        // Android 11+ (API level 30+) - Scoped Storage
        final status = await Permission.manageExternalStorage.request();
        permissionGranted = status.isGranted;
      } else {
        // Older Android versions
        final status = await Permission.storage.request();
        permissionGranted = status.isGranted;
      }

      if (!permissionGranted) {
        throw Exception('Storage permission denied');
      }

      // Get common music directories
      final musicDirs = await _getMusicDirectories();
      
      for (final dir in musicDirs) {
        if (await dir.exists()) {
          await _scanDirectoryForMusic(dir, musicFiles);
        }
      }
    } else {
      // For other platforms, scan available directories
      final directories = [
        await getApplicationDocumentsDirectory(),
        if (Platform.isWindows) Directory('C:\\Users\\Public\\Music'),
        if (Platform.isMacOS) Directory('/Users/${Platform.environment['USER']}/Music'),
      ];

      for (final dir in directories) {
        if (await dir.exists()) {
          await _scanDirectoryForMusic(dir, musicFiles);
        }
      }
    }

    return musicFiles;
  }

  Future<List<Directory>> _getMusicDirectories() async {
    final directories = <Directory>[];
    
    try {
      // Common Android music directories
      final commonPaths = [
        '/storage/emulated/0/Music',
        '/storage/emulated/0/Download',
        '/storage/emulated/0/DCIM',
        '/sdcard/Music',
        '/sdcard/Download',
      ];

      for (final path in commonPaths) {
        final dir = Directory(path);
        if (await dir.exists()) {
          directories.add(dir);
        }
      }

      // Try to get external storage directories
      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        directories.add(Directory('${externalDir.path}/Music'));
      }
    } catch (e) {
      debugPrint('Error getting music directories: $e');
    }

    return directories;
  }

  Future<void> _scanDirectoryForMusic(Directory dir, List<File> musicFiles) async {
    try {
      final supportedFormats = ['.mp3', '.wav', '.m4a', '.aac', '.flac', '.ogg'];
      
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final extension = entity.path.toLowerCase().split('.').last;
          if (supportedFormats.any((format) => format.contains(extension))) {
            musicFiles.add(entity);
          }
        }
      }
    } catch (e) {
      debugPrint('Error scanning directory ${dir.path}: $e');
    }
  }

  // Play a specific song
  Future<void> playSong(Song song) async {
    try {
      _setError(null);
      // Ensure we have metadata for the song
      _currentSong = await Song.fromFile(File(song.path));
      
      // Update playlist if not already set
      if (_playlist.isEmpty) {
        _playlist = List.from(_songs);
      }
      
      // Update current playlist index
      _currentPlaylistIndex = _playlist.indexWhere((s) => s.id == song.id);
      if (_currentPlaylistIndex == -1) {
        _currentPlaylistIndex = 0;
      }
      
      await _audioPlayer.setFilePath(_currentSong!.path);
      await _audioPlayer.play();
      
      // Show notification
      await NotificationService.showMusicNotification(
        title: _currentSong!.title,
        artist: _currentSong!.artist,
        isPlaying: true,
      );
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to play song: ${e.toString()}');
    }
  }

  // Set playlist and play from specific index
  Future<void> playFromPlaylist(List<Song> playlist, int index) async {
    if (playlist.isEmpty || index < 0 || index >= playlist.length) return;
    
    _playlist = List.from(playlist);
    _currentPlaylistIndex = index;
    await playSong(playlist[index]);
  }

  // Play/pause current song
  Future<void> togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      _setError('Failed to toggle playback: ${e.toString()}');
    }
  }

  // Stop current song
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentSong = null;
      _position = Duration.zero;
      await NotificationService.hideNotification();
      notifyListeners();
    } catch (e) {
      _setError('Failed to stop playback: ${e.toString()}');
    }
  }

  // Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _setError('Failed to seek: ${e.toString()}');
    }
  }

  // Play next song
  Future<void> playNext() async {
    if (_playlist.isEmpty) return;
    
    if (_isShuffleEnabled) {
      // Play random song (excluding current)
      final availableIndices = List.generate(_playlist.length, (i) => i)
          .where((i) => i != _currentPlaylistIndex)
          .toList();
      if (availableIndices.isNotEmpty) {
        final randomIndex = availableIndices[DateTime.now().millisecondsSinceEpoch % availableIndices.length];
        _currentPlaylistIndex = randomIndex;
        await playSong(_playlist[_currentPlaylistIndex]);
      }
    } else {
      // Play next song in order
      if (_currentPlaylistIndex < _playlist.length - 1) {
        _currentPlaylistIndex++;
        await playSong(_playlist[_currentPlaylistIndex]);
      } else if (_isRepeatEnabled) {
        // Loop back to start if repeat is enabled
        _currentPlaylistIndex = 0;
        await playSong(_playlist[_currentPlaylistIndex]);
      }
      // If we reach the end and repeat is disabled, stop playing
    }
  }

  // Play previous song
  Future<void> playPrevious() async {
    if (_playlist.isEmpty) return;
    
    if (_currentPlaylistIndex > 0) {
      _currentPlaylistIndex--;
      await playSong(_playlist[_currentPlaylistIndex]);
    } else if (_isRepeatEnabled) {
      // Loop to end if repeat is enabled
      _currentPlaylistIndex = _playlist.length - 1;
      await playSong(_playlist[_currentPlaylistIndex]);
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      _volume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(_volume);
      notifyListeners();
    } catch (e) {
      _setError('Failed to set volume: ${e.toString()}');
    }
  }

  // Toggle shuffle mode
  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }

  // Toggle repeat mode
  void toggleRepeat() {
    _isRepeatEnabled = !_isRepeatEnabled;
    notifyListeners();
  }

  // Toggle auto-play next
  void toggleAutoPlayNext() {
    _autoPlayNext = !_autoPlayNext;
    notifyListeners();
  }

  // Set shuffle mode
  void setShuffle(bool enabled) {
    _isShuffleEnabled = enabled;
    notifyListeners();
  }

  // Set repeat mode
  void setRepeat(bool enabled) {
    _isRepeatEnabled = enabled;
    notifyListeners();
  }

  // Set auto-play next
  void setAutoPlayNext(bool enabled) {
    _autoPlayNext = enabled;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _setError(null);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
