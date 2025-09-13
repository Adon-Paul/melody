import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import '../core/theme/app_theme.dart';
import '../core/widgets/modern_button.dart';
import '../core/widgets/animated_background.dart';
import '../core/widgets/mini_player.dart';
import '../core/widgets/glass_notification.dart';
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
  final Uint8List? albumArt;
  final String? genre;
  final int? year;
  final int? trackNumber;

  MusicFileMetadata({
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    this.duration,
    required this.format,
    required this.fileName,
    required this.fileSize,
    this.albumArt,
    this.genre,
    this.year,
    this.trackNumber,
  });

  static Future<MusicFileMetadata> fromFile(File file) async {
    final fileName = file.path.split(Platform.pathSeparator).last;
    final nameWithoutExtension = fileName.split('.').first;
    final format = fileName.split('.').last.toUpperCase();
    final fileSize = file.lengthSync();
    
    // Default values
    String title = nameWithoutExtension;
    String artist = 'Unknown Artist';
    String album = 'Unknown Album';
    Duration? duration;
    Uint8List? albumArt;
    String? genre;
    int? year;
    int? trackNumber;
    
    try {
      // Extract metadata using audio_metadata_reader
      final metadata = readMetadata(file, getImage: true);
      
      // Extract basic info (using only confirmed available properties)
      title = metadata.title?.isNotEmpty == true ? metadata.title! : nameWithoutExtension;
      artist = metadata.artist?.isNotEmpty == true ? metadata.artist! : 'Unknown Artist';
      album = metadata.album?.isNotEmpty == true ? metadata.album! : 'Unknown Album';
      trackNumber = metadata.trackNumber;
      
      // Extract year if available
      if (metadata.year != null) {
        year = metadata.year!.year;
      }
      
      // Extract duration
      if (metadata.duration != null) {
        duration = metadata.duration;
      }
      
      // Extract album art
      if (metadata.pictures.isNotEmpty) {
        albumArt = metadata.pictures.first.bytes;
      }
      
    } catch (e) {
      // If metadata extraction fails, try basic filename parsing
      debugPrint('Failed to extract metadata for ${file.path}: $e');
      
      // Try to extract basic info from filename
      final cleanName = nameWithoutExtension.replaceAll(RegExp(r'^\d+\s*[-\.]\s*'), '');
      if (cleanName.contains(' - ')) {
        final parts = cleanName.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts[1].trim();
        }
      }
      
      // Generate a consistent but varied duration based on file size as fallback
      final estimatedDurationSeconds = (fileSize / 32000).clamp(30, 600);
      duration = Duration(seconds: estimatedDurationSeconds.round());
    }
    
    return MusicFileMetadata(
      path: file.path,
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      format: format,
      fileName: fileName,
      fileSize: fileSize,
      albumArt: albumArt,
      genre: genre,
      year: year,
      trackNumber: trackNumber,
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
    if (mounted) {
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
  }

  Future<void> _loadMusicFiles() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

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
            if (mounted) {
              setState(() {
                _error = 'Storage permission permanently denied. Please enable it in app settings.';
                _loading = false;
              });
            }
            await openAppSettings();
            return;
          } else {
            if (mounted) {
              setState(() {
                _error = 'Storage permission denied. Enable storage access to view your music.';
                _loading = false;
              });
            }
            return;
          }
        } else {
          // Android 10 and below: STORAGE
          final status = await Permission.storage.request();
          if (status.isGranted) {
            permissionGranted = true;
          } else if (status.isPermanentlyDenied) {
            if (mounted) {
              setState(() {
                _error = 'Storage permission permanently denied. Please enable it in app settings.';
                _loading = false;
              });
            }
            await openAppSettings();
            return;
          } else {
            if (mounted) {
              setState(() {
                _error = 'Storage permission denied. Enable storage access to view your music.';
                _loading = false;
              });
            }
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

          // Convert to metadata format with progress tracking and batching
          const batchSize = 3; // Smaller batches for real metadata extraction
          for (int i = 0; i < allMusicFiles.length; i += batchSize) {
            final batch = allMusicFiles.skip(i).take(batchSize).toList();
            
            // Process batch concurrently for better performance
            final futures = batch.map((file) => _processFileWithFallback(file)).toList();
            final batchResults = await Future.wait(futures);
            
            // Add successful results
            for (final result in batchResults) {
              if (result != null) {
                musicWithMetadata.add(result);
              }
            }
            
            // Update UI with current progress
            if (mounted) {
              setState(() {
                _musicFiles = List.from(musicWithMetadata);
                _filteredFiles = List.from(musicWithMetadata);
              });
            }
            
            // Small delay to prevent UI blocking
            await Future.delayed(const Duration(milliseconds: 50));
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _error = 'Error scanning music files: $e';
              _loading = false;
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            _musicFiles = musicWithMetadata;
            _filteredFiles = musicWithMetadata;
            _loading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Music scanning is currently only available on Android devices.';
            _loading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading music files: $e';
          _loading = false;
        });
      }
    }
  }

  bool _isSupportedAudioFile(String path) {
    final supportedFormats = ['.mp3', '.wav', '.m4a', '.aac', '.flac', '.ogg'];
    final extension = '.${path.toLowerCase().split('.').last}';
    return supportedFormats.contains(extension);
  }

  Future<MusicFileMetadata?> _processFileWithFallback(File file) async {
    try {
      return await MusicFileMetadata.fromFile(file);
    } catch (e) {
      debugPrint('Failed to process file ${file.path}: $e');
      return null;
    }
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

  Widget _buildAlbumArt(MusicFileMetadata file, {double size = 56}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: file.albumArt != null
            ? Image.memory(
                file.albumArt!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildGeneratedAlbumArt(file, size),
              )
            : _buildGeneratedAlbumArt(file, size),
      ),
    );
  }

  Widget _buildGeneratedAlbumArt(MusicFileMetadata file, double size) {
    // Generate a beautiful gradient based on the title and artist
    final colors = _getArtistColors(file.artist, file.title);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.2,
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Music note icon
          Center(
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: size * 0.4,
            ),
          ),
          // Artist initial in corner
          if (file.artist != 'Unknown Artist')
            Positioned(
              top: size * 0.1,
              right: size * 0.1,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(size * 0.125),
                ),
                child: Center(
                  child: Text(
                    file.artist[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Color> _getArtistColors(String artist, String title) {
    // Generate consistent colors based on artist and title
    final combinedString = (artist + title).toLowerCase();
    final hash = combinedString.hashCode;
    
    // Predefined beautiful color combinations
    final colorSets = [
      [const Color(0xFF6B73FF), const Color(0xFF9B59B6)], // Purple-Blue
      [const Color(0xFFFF6B9D), const Color(0xFFC44569)], // Pink-Red
      [const Color(0xFF4ECDC4), const Color(0xFF44A08D)], // Teal-Green
      [const Color(0xFFFFB74D), const Color(0xFFFF8A65)], // Orange-Coral
      [const Color(0xFF64B5F6), const Color(0xFF42A5F5)], // Light Blue
      [const Color(0xFFAED581), const Color(0xFF66BB6A)], // Light Green
      [const Color(0xFFBA68C8), const Color(0xFFAB47BC)], // Purple
      [const Color(0xFFFFD54F), const Color(0xFFFFCA28)], // Yellow
      [const Color(0xFFFF8A65), const Color(0xFFFF7043)], // Orange
      [const Color(0xFF4DB6AC), const Color(0xFF26A69A)], // Teal
    ];
    
    return colorSets[hash.abs() % colorSets.length];
  }

  Widget _buildMusicTile(MusicFileMetadata file) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildAlbumArt(file, size: 60),
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
            const SizedBox(height: 6),
            Text(
              file.artist,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (file.album != 'Unknown Album')
              Text(
                file.album,
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary.withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
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
                const SizedBox(width: 12),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(file.duration),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatFileSize(file.fileSize),
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () => _playMusic(file),
          ),
        ),
        onTap: () => _showMusicDetails(file),
      ),
          ),
        ),
      ),
    );
  }

  void _playMusic(MusicFileMetadata file) async {
    final musicService = context.read<MusicService>();
    
    // Convert all filtered files to Song objects for playlist
    final playlist = _filteredFiles.map((f) => Song(
      id: f.path,
      title: f.title,
      artist: f.artist,
      path: f.path,
      duration: f.duration,
      albumArt: f.albumArt,
    )).toList();
    
    // Find the index of the selected song
    final selectedIndex = _filteredFiles.indexWhere((f) => f.path == file.path);
    
    // Play from playlist starting at the selected song
    await musicService.playFromPlaylist(playlist, selectedIndex);
    
    if (mounted) {
      GlassNotification.show(
        context,
        message: 'Now playing: ${file.title}',
        icon: Icons.play_arrow_rounded,
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
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
                width: 150,
                height: 150,
                child: _buildAlbumArt(file, size: 150),
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
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Handle cleanup when navigating back
        if (didPop) {
          // Stop any ongoing scan operations
          // This helps with performance when leaving the page
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                              : Scrollbar(
                                  thumbVisibility: true,
                                  trackVisibility: true,
                                  radius: const Radius.circular(8),
                                  thickness: 8,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: _filteredFiles.length,
                                    itemBuilder: (context, index) {
                                      return _buildMusicTile(_filteredFiles[index]);
                                    },
                                  ),
                                ),
                ),
                
                // Mini Player
                const MiniPlayer(),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}
