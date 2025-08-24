import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'dart:async';
import '../core/theme/app_theme.dart';
import '../core/services/music_service.dart';
import '../core/services/favorites_service.dart';
import '../core/services/advanced_lyrics_sync_service.dart';
import '../core/widgets/animated_background.dart';
import '../core/widgets/glass_notification.dart';
import 'widgets/precision_lyrics_widget.dart';
import 'widgets/lyrics_settings_dialog.dart';

class FullMusicPlayerPage extends StatefulWidget {
  const FullMusicPlayerPage({super.key});

  @override
  State<FullMusicPlayerPage> createState() => _FullMusicPlayerPageState();
}

class _FullMusicPlayerPageState extends State<FullMusicPlayerPage>
    with TickerProviderStateMixin {
  late AnimationController _albumRotationController;
  late AnimationController _fadeController;
  late AnimationController _lyricsController;
  late ScrollController _lyricsScrollController;
  Timer? _lyricsUpdateTimer;
  bool _isDraggingSeek = false;
  bool _lyricsMinimized = false;
  Duration _seekPosition = Duration.zero;
  MusicService? _musicService;
  AdvancedLyricsSyncService? _lyricsService;
  String? _lastLoadedSong; // Track the last song we loaded lyrics for

  @override
  void initState() {
    super.initState();
    _albumRotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _lyricsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _lyricsScrollController = ScrollController();
    _fadeController.forward();
    
    // Store reference to music service for safer disposal
    _musicService = context.read<MusicService>();
    _lyricsService = context.read<AdvancedLyricsSyncService>();
    
    // Start album rotation if playing
    if (_musicService!.isPlaying) {
      _albumRotationController.repeat();
    }

    // Listen for song changes to update lyrics
    _musicService!.addListener(_onSongChanged);

    // Initialize lyrics service and fetch lyrics for current song
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLyrics();
      _startLyricsUpdateTimer();
    });
  }

  void _onSongChanged() {
    if (mounted && _musicService?.currentSong != null) {
      final currentSong = _musicService!.currentSong!;
      final songId = '${currentSong.artist}-${currentSong.title}';
      
      // Only initialize lyrics if this is a genuinely new song
      if (songId != _lastLoadedSong) {
        _initializeLyrics();
      } else {
        // Just update sync state for the same song
        if (_musicService!.isPlaying) {
          _lyricsService?.syncToPosition(_musicService!.position);
        } else {
          _lyricsService?.pauseSync();
        }
      }
    }
  }

  @override
  void dispose() {
    // Cancel timer first to prevent any further updates
    _lyricsUpdateTimer?.cancel();
    
    // Remove listener safely without accessing context
    _musicService?.removeListener(_onSongChanged);
    
    // Dispose animation controllers
    _albumRotationController.dispose();
    _fadeController.dispose();
    _lyricsController.dispose();
    _lyricsScrollController.dispose();
    
    super.dispose();
  }

  void _initializeLyrics() async {
    if (!mounted || _musicService == null || _lyricsService == null) return;
    
    final currentSong = _musicService!.currentSong;
    if (currentSong == null) return;
    
    // Create a unique identifier for the current song
    final songId = '${currentSong.artist}-${currentSong.title}';
    
    // Don't reload lyrics if we already have them for this song
    if (_lastLoadedSong == songId && _lyricsService!.hasLyrics) {
      // Just sync to current position if song is playing
      if (_musicService!.isPlaying) {
        _lyricsService!.startSync();
      }
      return;
    }
    
    await _lyricsService!.initialize();
    
    // Load lyrics for the new song
    await _lyricsService!.loadLyrics(
      currentSong.artist,
      currentSong.title,
    );
    
    // Remember this song so we don't reload unnecessarily
    _lastLoadedSong = songId;
    
    // Start synchronization if song is playing
    if (_musicService!.isPlaying) {
      _lyricsService!.startSync();
    }
  }

  void _startLyricsUpdateTimer() {
    _lyricsUpdateTimer?.cancel();
    _lyricsUpdateTimer = Timer.periodic(const Duration(milliseconds: 2000), (timer) {
      // Check if widget is still mounted before attempting updates
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        if (!mounted || _musicService == null || _lyricsService == null) {
          timer.cancel();
          return;
        }
        
        if (_musicService!.isPlaying && _lyricsService!.hasLyrics) {
          _lyricsService!.syncToPosition(_musicService!.position);
        }
      } catch (e) {
        // Silently handle any context errors when widget is unmounting
        timer.cancel();
      }
    });
  }

  void _toggleLyricsMinimize() {
    setState(() {
      _lyricsMinimized = !_lyricsMinimized;
    });
    if (_lyricsMinimized) {
      _lyricsController.reverse();
    } else {
      _lyricsController.forward();
    }
  }

  void _showLyricsSettings(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const LyricsSettingsDialog(),
    );
  }

  Widget _buildLyricsBox(MusicService musicService) {
    final screenHeight = MediaQuery.of(context).size.height;
    final expandedHeight = screenHeight < 700 ? 540.0 : 660.0; // Tripled from 180/220
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: _lyricsMinimized ? 60 : expandedHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.2),
                  AppTheme.accentColor.withValues(alpha: 0.15),
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header with minimize button
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lyrics_rounded,
                        color: Colors.white.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lyrics',
                        style: AppTheme.titleMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // Settings button
                      GestureDetector(
                        onTap: () => _showLyricsSettings(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.settings_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _toggleLyricsMinimize,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _lyricsMinimized ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Lyrics content (hidden when minimized)
                if (!_lyricsMinimized) ...[
                  const Divider(
                    color: Colors.white24,
                    height: 1,
                    thickness: 0.5,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: PrecisionLyricsWidget(
                        showTimestamps: false,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildAlbumArt(Song song, {double size = 200}) {
    Widget albumWidget;
    
    if (song.albumArt != null) {
      albumWidget = ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.1),
        child: Image.memory(
          song.albumArt!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildGeneratedAlbumArt(song, size);
          },
        ),
      );
    } else {
      albumWidget = _buildGeneratedAlbumArt(song, size);
    }

    return Consumer<MusicService>(
      builder: (context, musicService, child) {
        // Control rotation based on play state
        if (musicService.isPlaying && !_albumRotationController.isAnimating) {
          _albumRotationController.repeat();
        } else if (!musicService.isPlaying && _albumRotationController.isAnimating) {
          _albumRotationController.stop();
        }

        return RotationTransition(
          turns: _albumRotationController,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: albumWidget,
          ),
        );
      },
    );
  }

  Widget _buildGeneratedAlbumArt(Song song, double size) {
    final colors = _getArtistColors(song.artist, song.title);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.1),
      ),
      child: Center(
        child: Text(
          song.artist.isNotEmpty ? song.artist[0].toUpperCase() : '♪',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.2,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<Color> _getArtistColors(String artist, String title) {
    final combinedString = (artist + title).toLowerCase();
    final hash = combinedString.hashCode;
    
    final colorSets = [
      [const Color(0xFF6B73FF), const Color(0xFF9B59B6)],
      [const Color(0xFFFF6B9D), const Color(0xFFC44569)],
      [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
      [const Color(0xFFFFB74D), const Color(0xFFFF8A65)],
      [const Color(0xFF64B5F6), const Color(0xFF42A5F5)],
      [const Color(0xFFAED581), const Color(0xFF66BB6A)],
      [const Color(0xFFBA68C8), const Color(0xFFAB47BC)],
      [const Color(0xFFFFD54F), const Color(0xFFFFCA28)],
      [const Color(0xFFFF8A65), const Color(0xFFFF7043)],
      [const Color(0xFF4DB6AC), const Color(0xFF26A69A)],
    ];
    
    return colorSets[hash.abs() % colorSets.length];
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    double size = 60,
    bool isPrimary = false,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: isPrimary ? AppTheme.primaryGradient : null,
        color: isPrimary ? null : AppTheme.surfaceColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isPrimary ? AppTheme.primaryColor : Colors.black)
                .withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Icon(
            icon,
            color: isPrimary ? Colors.white : AppTheme.textPrimary,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<MusicService>(
        builder: (context, musicService, child) {
          final song = musicService.currentSong;
          if (song == null) {
            return const Center(
              child: Text('No song playing'),
            );
          }

          return Stack(
            children: [
              const AnimatedBackground(),
              
              // Glass overlay for better readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppTheme.backgroundColor.withValues(alpha: 0.7),
                      AppTheme.backgroundColor.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppTheme.textPrimary,
                                size: 32,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'Now Playing',
                                style: AppTheme.headlineMedium.copyWith(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Consumer<FavoritesService>(
                              builder: (context, favoritesService, child) {
                                final isFavorite = favoritesService.isFavorite(song.id);
                                return IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? Colors.red : AppTheme.textPrimary,
                                    size: 28,
                                  ),
                                  onPressed: () {
                                    if (isFavorite) {
                                      favoritesService.removeFavorite(song.id);
                                      GlassNotification.show(
                                        context,
                                        message: 'Removed from favorites',
                                        icon: Icons.favorite_border,
                                        backgroundColor: AppTheme.surfaceColor.withValues(alpha: 0.2),
                                      );
                                    } else {
                                      favoritesService.addFavorite(song);
                                      GlassNotification.show(
                                        context,
                                        message: 'Added to favorites',
                                        icon: Icons.favorite,
                                        backgroundColor: Colors.red.withValues(alpha: 0.2),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Album Art
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive album art size
                          final screenHeight = MediaQuery.of(context).size.height;
                          final albumSize = screenHeight < 700 ? 220.0 : 280.0;
                          return _buildAlbumArt(song, size: albumSize);
                        },
                      ),

                      const SizedBox(height: 30),

                      // Song Info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            Text(
                              song.title,
                              style: AppTheme.headlineMedium.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              song.artist,
                              style: AppTheme.titleMedium.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Progress Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                activeTrackColor: AppTheme.primaryColor,
                                inactiveTrackColor: AppTheme.textSecondary.withValues(alpha: 0.3),
                                thumbColor: AppTheme.primaryColor,
                                overlayColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: () {
                                  final duration = musicService.duration.inMilliseconds.toDouble();
                                  if (duration <= 0) return 0.0;
                                  
                                  final position = _isDraggingSeek 
                                      ? _seekPosition.inMilliseconds.toDouble()
                                      : musicService.position.inMilliseconds.toDouble();
                                  
                                  return position.clamp(0.0, duration);
                                }(),
                                min: 0,
                                max: musicService.duration.inMilliseconds.toDouble().clamp(1.0, double.infinity),
                                onChanged: (value) {
                                  setState(() {
                                    _isDraggingSeek = true;
                                    _seekPosition = Duration(milliseconds: value.toInt());
                                  });
                                },
                                onChangeEnd: (value) {
                                  final position = Duration(milliseconds: value.toInt());
                                  musicService.seek(position);
                                  setState(() {
                                    _isDraggingSeek = false;
                                  });
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_isDraggingSeek ? _seekPosition : musicService.position),
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                Text(
                                  _formatDuration(musicService.duration),
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Control Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildControlButton(
                              icon: Icons.skip_previous_rounded,
                              onPressed: () {
                                musicService.playPrevious();
                                GlassNotification.show(
                                  context,
                                  message: 'Previous track',
                                  icon: Icons.skip_previous_rounded,
                                );
                              },
                              size: 60,
                            ),
                            _buildControlButton(
                              icon: musicService.isPlaying 
                                  ? Icons.pause_rounded 
                                  : Icons.play_arrow_rounded,
                              onPressed: () {
                                final wasPlaying = musicService.isPlaying;
                                musicService.togglePlayPause();
                                
                                GlassNotification.show(
                                  context,
                                  message: wasPlaying ? 'Paused' : 'Playing',
                                  icon: wasPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  backgroundColor: wasPlaying 
                                      ? AppTheme.surfaceColor.withValues(alpha: 0.2)
                                      : AppTheme.primaryColor.withValues(alpha: 0.2),
                                );
                              },
                              size: 80,
                              isPrimary: true,
                            ),
                            _buildControlButton(
                              icon: Icons.skip_next_rounded,
                              onPressed: () {
                                musicService.playNext();
                                GlassNotification.show(
                                  context,
                                  message: 'Next track',
                                  icon: Icons.skip_next_rounded,
                                );
                              },
                              size: 60,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Additional Controls Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildControlButton(
                              icon: musicService.isShuffleEnabled 
                                  ? Icons.shuffle_on_rounded 
                                  : Icons.shuffle_rounded,
                              onPressed: () {
                                musicService.toggleShuffle();
                                GlassNotification.show(
                                  context,
                                  message: musicService.isShuffleEnabled ? 'Shuffle on' : 'Shuffle off',
                                  icon: Icons.shuffle_rounded,
                                );
                              },
                              size: 50,
                            ),
                            _buildControlButton(
                              icon: musicService.isRepeatEnabled 
                                  ? Icons.repeat_one_rounded 
                                  : Icons.repeat_rounded,
                              onPressed: () {
                                musicService.toggleRepeat();
                                GlassNotification.show(
                                  context,
                                  message: musicService.isRepeatEnabled ? 'Repeat on' : 'Repeat off',
                                  icon: Icons.repeat_rounded,
                                );
                              },
                              size: 50,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Volume Control
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          children: [
                            Icon(
                              Icons.volume_down,
                              color: AppTheme.textSecondary,
                            ),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                  activeTrackColor: AppTheme.primaryColor,
                                  inactiveTrackColor: AppTheme.textSecondary.withValues(alpha: 0.3),
                                  thumbColor: AppTheme.primaryColor,
                                  overlayColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                ),
                                child: Slider(
                                  value: musicService.volume,
                                  min: 0,
                                  max: 1,
                                  onChanged: (value) {
                                    musicService.setVolume(value);
                                  },
                                ),
                              ),
                            ),
                            Icon(
                              Icons.volume_up,
                              color: AppTheme.textSecondary,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Lyrics Box
                      _buildLyricsBox(musicService),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
