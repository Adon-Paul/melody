import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../core/theme/app_theme.dart';
import '../core/widgets/modern_button.dart';
import '../core/widgets/animated_background.dart';
import '../core/services/music_service.dart';

class MusicFileMetadata {
  final String path;
  final String title;
  final String artist;
  final String album;
  final Duration? duration;
  final String format;
  final String fileName;
  final int fileSize;

  MusicFileMetadata({
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    this.duration,
    required this.format,
    required this.fileName,
    required this.fileSize,
  });

  static MusicFileMetadata fromFile(File file) {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final nameWithoutExtension = fileName.split('.').first;
    final format = fileName.split('.').last.toUpperCase();
    final fileSize = file.lengthSync();
    
    return MusicFileMetadata(
      path: file.path,
      title: nameWithoutExtension,
      artist: 'Unknown Artist',
      album: 'Unknown Album',
      format: format,
      fileName: fileName,
      fileSize: fileSize,
    );
  }
}

class DeviceMusicPage extends StatefulWidget {
  const DeviceMusicPage({super.key});

  @override
  State<DeviceMusicPage> createState() => _DeviceMusicPageState();
}

class _DeviceMusicPageState extends State<DeviceMusicPage> {
  List<MusicFileMetadata> _musicFiles = [];
  List<MusicFileMetadata> _filteredFiles = [];
  bool _loading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMusicFiles();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredFiles = _musicFiles.where((file) {
        return file.title.toLowerCase().contains(_searchQuery) ||
               file.artist.toLowerCase().contains(_searchQuery) ||
               file.album.toLowerCase().contains(_searchQuery) ||
               file.fileName.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  Future<void> _loadMusicFiles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (Platform.isAndroid) {
        bool permissionGranted = false;
        
        // Check Android version for permission handling
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        
        if (sdkInt >= 30) {
          // Android 11+ (API 30+): MANAGE_EXTERNAL_STORAGE
          final status = await Permission.manageExternalStorage.request();
          if (status.isGranted) {
            permissionGranted = true;
          } else if (status.isPermanentlyDenied) {
            setState(() {
              _error = 'Storage permission permanently denied. Please enable it in app settings.';
              _loading = false;
            });
            await openAppSettings();
            return;
          } else {
            setState(() {
              _error = 'Storage permission denied. Enable storage access to view your music.';
              _loading = false;
            });
            return;
          }
        } else {
          // Android 10 and below: STORAGE
          final status = await Permission.storage.request();
          if (status.isGranted) {
            permissionGranted = true;
          } else if (status.isPermanentlyDenied) {
            setState(() {
              _error = 'Storage permission permanently denied. Please enable it in app settings.';
              _loading = false;
            });
            await openAppSettings();
            return;
          } else {
            setState(() {
              _error = 'Storage permission denied. Enable storage access to view your music.';
              _loading = false;
            });
            return;
          }
        }

        if (!permissionGranted) return;

        // Scan for music files
        List<File> allMusicFiles = [];
        List<MusicFileMetadata> musicWithMetadata = [];
        
        try {
          // Common music directories to scan
          final musicDirs = [
            '/storage/emulated/0/Music',
            '/storage/emulated/0/Download',
            '/storage/emulated/0/DCIM',
            '/sdcard/Music',
            '/sdcard/Download',
          ];

          for (final dirPath in musicDirs) {
            final dir = Directory(dirPath);
            if (await dir.exists()) {
              await for (final entity in dir.list(recursive: true, followLinks: false)) {
                if (entity is File && _isSupportedAudioFile(entity.path)) {
                  allMusicFiles.add(entity);
                }
              }
            }
          }

          // Convert to metadata format
          for (final file in allMusicFiles) {
            try {
              final musicFile = MusicFileMetadata.fromFile(file);
              musicWithMetadata.add(musicFile);
            } catch (e) {
              // Skip files with errors
              continue;
            }
          }
        } catch (e) {
          setState(() {
            _error = 'Error scanning music files: $e';
            _loading = false;
          });
          return;
        }

        setState(() {
          _musicFiles = musicWithMetadata;
          _filteredFiles = musicWithMetadata;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Music scanning is currently only available on Android devices.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading music files: $e';
        _loading = false;
      });
    }
  }

  bool _isSupportedAudioFile(String path) {
    final supportedFormats = ['.mp3', '.wav', '.m4a', '.aac', '.flac', '.ogg'];
    final extension = '.${path.toLowerCase().split('.').last}';
    return supportedFormats.contains(extension);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildAlbumArt(MusicFileMetadata file) {
    // For now, use a default music icon since we're not extracting album art
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: AppTheme.primaryGradient,
      ),
      child: const Icon(
        Icons.music_note,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildMusicTile(MusicFileMetadata file) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildAlbumArt(file),
        title: Text(
          file.title,
          style: AppTheme.titleMedium.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              file.artist,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    file.format,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(file.duration),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.play_arrow_rounded,
            color: AppTheme.primaryColor,
            size: 32,
          ),
          onPressed: () => _playMusic(file),
        ),
        onTap: () => _showMusicDetails(file),
      ),
    );
  }

  void _playMusic(MusicFileMetadata file) async {
    final musicService = context.read<MusicService>();
    
    // Convert to Song object and play
    final song = Song(
      id: file.path,
      title: file.title,
      artist: file.artist,
      path: file.path,
      duration: file.duration,
    );
    
    await musicService.playSong(song);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Now playing: ${file.title}'),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showMusicDetails(MusicFileMetadata file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Album Art
              SizedBox(
                width: 120,
                height: 120,
                child: _buildAlbumArt(file),
              ),
              const SizedBox(height: 16),
              
              // Title
              Text(
                file.title,
                style: AppTheme.titleLarge.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Artist
              Text(
                file.artist,
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Album', file.album),
                    const SizedBox(height: 8),
                    _buildDetailRow('Duration', _formatDuration(file.duration)),
                    const SizedBox(height: 8),
                    _buildDetailRow('Format', file.format),
                    const SizedBox(height: 8),
                    _buildDetailRow('Size', _formatFileSize(file.fileSize)),
                    const SizedBox(height: 8),
                    _buildDetailRow('File', file.fileName),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ModernButton(
                      text: 'Close',
                      onPressed: () => Navigator.pop(context),
                      variant: ButtonVariant.outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ModernButton(
                      text: 'Play',
                      onPressed: () {
                        Navigator.pop(context);
                        _playMusic(file);
                      },
                      iconData: Icons.play_arrow,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            '$label:',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Top Bar
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: AppTheme.textPrimary,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              'Device Music',
                              style: AppTheme.headlineMedium.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: AppTheme.primaryColor,
                            ),
                            onPressed: _loadMusicFiles,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search music files...',
                            hintStyle: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppTheme.primaryColor,
                            ),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(
                                      Icons.clear_rounded,
                                      color: AppTheme.textSecondary,
                                    ),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                      
                      // Results Counter
                      if (!_loading && _error == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _searchQuery.isEmpty
                                ? '${_musicFiles.length} music files found'
                                : '${_filteredFiles.length} results for "$_searchQuery"',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: _loading
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Scanning for music files...',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Container(
                                margin: const EdgeInsets.all(24),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.errorColor.withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      size: 48,
                                      color: AppTheme.errorColor,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _error!,
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: AppTheme.errorColor,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 24),
                                    ModernButton(
                                      text: 'Retry',
                                      onPressed: _loadMusicFiles,
                                      iconData: Icons.refresh_rounded,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _filteredFiles.isEmpty
                              ? Center(
                                  child: Container(
                                    margin: const EdgeInsets.all(24),
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _searchQuery.isEmpty ? Icons.music_off_rounded : Icons.search_off_rounded,
                                          size: 48,
                                          color: AppTheme.textSecondary,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _searchQuery.isEmpty
                                              ? 'No music files found on your device'
                                              : 'No results found for "$_searchQuery"',
                                          style: AppTheme.bodyMedium.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        if (_searchQuery.isEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text(
                                            'Supported formats: MP3, WAV, M4A, AAC, FLAC, OGG',
                                            style: AppTheme.bodySmall.copyWith(
                                              color: AppTheme.textSecondary.withValues(alpha: 0.7),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  itemCount: _filteredFiles.length,
                                  itemBuilder: (context, index) {
                                    return _buildMusicTile(_filteredFiles[index]);
                                  },
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
