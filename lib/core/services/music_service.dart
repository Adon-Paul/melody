import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class Song {
  final String id;
  final String title;
  final String artist;
  final String path;
  final Duration? duration;
  final String? albumArt;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.path,
    this.duration,
    this.albumArt,
  });

  factory Song.fromFile(File file) {
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

class MusicService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  List<Song> _songs = [];
  Song? _currentSong;
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  String? _errorMessage;

  // Getters
  List<Song> get songs => _songs;
  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get position => _position;
  Duration get duration => _duration;
  String? get errorMessage => _errorMessage;
  double get progress => _duration.inMilliseconds > 0
      ? _position.inMilliseconds / _duration.inMilliseconds
      : 0.0;

  MusicService() {
    _init();
  }

  void _init() {
    // Listen to player state changes
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Load songs from device storage
  Future<void> loadSongs() async {
    try {
      _setLoading(true);
      _setError(null);
      
      final musicFiles = await _getMusicFiles();
      _songs = musicFiles.map((file) => Song.fromFile(file)).toList();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load music files: ${e.toString()}');
    } finally {
      _setLoading(false);
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
      _currentSong = song;
      
      await _audioPlayer.setFilePath(song.path);
      await _audioPlayer.play();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to play song: ${e.toString()}');
    }
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
    if (_currentSong == null || _songs.isEmpty) return;
    
    final currentIndex = _songs.indexWhere((song) => song.id == _currentSong!.id);
    if (currentIndex < _songs.length - 1) {
      await playSong(_songs[currentIndex + 1]);
    }
  }

  // Play previous song
  Future<void> playPrevious() async {
    if (_currentSong == null || _songs.isEmpty) return;
    
    final currentIndex = _songs.indexWhere((song) => song.id == _currentSong!.id);
    if (currentIndex > 0) {
      await playSong(_songs[currentIndex - 1]);
    }
  }

  // Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      _setError('Failed to set volume: ${e.toString()}');
    }
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
