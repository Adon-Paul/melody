import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../core/theme/app_theme.dart';
import '../core/services/music_service.dart';
import '../core/services/favorites_service.dart';
import '../core/services/advanced_lyrics_sync_service.dart';
import '../core/services/beat_visualizer_service.dart';
import '../core/widgets/animated_background.dart';
import '../core/widgets/glass_notification.dart';
import 'widgets/compact_lyrics_widget.dart';

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
  late AnimationController _albumTransitionController;
  late ScrollController _lyricsScrollController;
  late Animation<Offset> _albumSlideOutAnimation;
  late Animation<Offset> _albumSlideInAnimation;
  Timer? _lyricsUpdateTimer;
  bool _isDraggingSeek = false;
  Duration _seekPosition = Duration.zero;
  MusicService? _musicService;
  AdvancedLyricsSyncService? _lyricsService;
  late BeatVisualizerService _beatVisualizer;
  String? _lastLoadedSong; // Track the last song we loaded lyrics for
  Song? _currentDisplayedSong; // Track currently displayed song for transitions
  Song? _previousDisplayedSong; // Track previous song for transition
  bool _isGoingForward = true; // Track direction of song change

  @override
  void initState() {
    super.initState();
    _beatVisualizer = BeatVisualizerService();
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
    _albumTransitionController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Previous album slides out to the left (forward) or right (backward)
    _albumSlideOutAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.2, 0), // Will be dynamically set based on direction
    ).animate(CurvedAnimation(
      parent: _albumTransitionController,
      curve: Curves.easeInCubic,
    ));
    
    // New album slides in from the right (forward) or left (backward)
    _albumSlideInAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0), // Will be dynamically set based on direction
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _albumTransitionController,
      curve: Curves.easeOutCubic,
    ));
    _lyricsScrollController = ScrollController();
    _fadeController.forward();
    _albumTransitionController.forward();
    
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
    _albumTransitionController.dispose();
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

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _updateAnimationDirection(bool isForward) {
    _isGoingForward = isForward;
    
    // Update slide animations based on direction
    if (isForward) {
      // Forward: slide out left, slide in from right
      _albumSlideOutAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-1.2, 0),
      ).animate(CurvedAnimation(
        parent: _albumTransitionController,
        curve: Curves.easeInCubic,
      ));
      
      _albumSlideInAnimation = Tween<Offset>(
        begin: const Offset(1.2, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _albumTransitionController,
        curve: Curves.easeOutCubic,
      ));
    } else {
      // Backward: slide out right, slide in from left
      _albumSlideOutAnimation = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(1.2, 0),
      ).animate(CurvedAnimation(
        parent: _albumTransitionController,
        curve: Curves.easeInCubic,
      ));
      
      _albumSlideInAnimation = Tween<Offset>(
        begin: const Offset(-1.2, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _albumTransitionController,
        curve: Curves.easeOutCubic,
      ));
    }
  }

  Widget _buildAlbumArt(Song song, {double size = 200}) {
    // Check if this is a new song and determine direction
    if (_currentDisplayedSong == null || _currentDisplayedSong!.id != song.id) {
      _previousDisplayedSong = _currentDisplayedSong;
      
      // Determine direction by accessing MusicService
      if (_previousDisplayedSong != null) {
        try {
          // Try to get music service from context
          final musicService = Provider.of<MusicService>(context, listen: false);
          
          // Try to determine direction based on playlist index
          final playlist = musicService.playlist;
          if (playlist.isNotEmpty) {
            final currentIndex = playlist.indexWhere((s) => s.id == song.id);
            final previousIndex = playlist.indexWhere((s) => s.id == _previousDisplayedSong!.id);
            
            if (currentIndex != -1 && previousIndex != -1) {
              // Normal forward/backward detection
              _isGoingForward = currentIndex > previousIndex || 
                               (previousIndex == playlist.length - 1 && currentIndex == 0); // Wrap around
            } else {
              // Fallback: assume forward if we can't determine
              _isGoingForward = true;
            }
          } else {
            // No playlist context, assume forward
            _isGoingForward = true;
          }
        } catch (e) {
          // If we can't access provider, assume forward
          _isGoingForward = true;
        }
        
        // Update animation direction
        _updateAnimationDirection(_isGoingForward);
      }
      
      _currentDisplayedSong = song;
      
      // Only animate if we had a previous song (not on first load)
      if (_previousDisplayedSong != null) {
        _albumTransitionController.reset();
        _albumTransitionController.forward();
      }
    }

    return Consumer<MusicService>(
      builder: (context, musicService, child) {
        // Control rotation based on play state
        if (musicService.isPlaying && !_albumRotationController.isAnimating) {
          _albumRotationController.repeat();
        } else if (!musicService.isPlaying && _albumRotationController.isAnimating) {
          _albumRotationController.stop();
        }

        return Container(
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
          child: AnimatedBuilder(
            animation: _albumTransitionController,
            builder: (context, child) {
              return Stack(
                children: [
                  // Previous album art (sliding out to the left)
                  if (_previousDisplayedSong != null)
                    SlideTransition(
                      position: _albumSlideOutAnimation,
                      child: FadeTransition(
                        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                          CurvedAnimation(
                            parent: _albumTransitionController,
                            curve: const Interval(0.0, 0.7, curve: Curves.easeInQuart),
                          ),
                        ),
                        child: Transform.scale(
                          scale: Tween<double>(begin: 1.0, end: 0.8).animate(
                            CurvedAnimation(
                              parent: _albumTransitionController,
                              curve: Curves.easeInCubic,
                            ),
                          ).value,
                          child: RotationTransition(
                            turns: _albumRotationController,
                            child: _buildAlbumArtWidget(_previousDisplayedSong!, size),
                          ),
                        ),
                      ),
                    ),
                  // Current album art (sliding in from the right)
                  SlideTransition(
                    position: _albumSlideInAnimation,
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _albumTransitionController,
                          curve: const Interval(0.3, 1.0, curve: Curves.easeOutQuart),
                        ),
                      ),
                      child: Transform.scale(
                        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _albumTransitionController,
                            curve: Curves.easeOutCubic,
                          ),
                        ).value,
                        child: RotationTransition(
                          turns: _albumRotationController,
                          child: _buildAlbumArtWidget(song, size),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAlbumArtWidget(Song song, double size) {
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

    // Wrap with beat-synchronized glow effect
    return AnimatedBuilder(
      animation: _beatVisualizer,
      builder: (context, child) {
        return Container(
          decoration: _beatVisualizer.applyBeatGlow(
            BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),
          child: albumWidget,
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

  Widget _buildBottomControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    double size = 48,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive 
          ? AppTheme.primaryColor.withValues(alpha: 0.2)
          : Colors.transparent,
        border: Border.all(
          color: isActive 
            ? AppTheme.primaryColor.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Icon(
            icon,
            color: isActive ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.7),
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back navigation
      onPopInvokedWithResult: (didPop, result) async {
        // Handle back gesture by minimizing to mini player
        if (!didPop) {
          try {
            // Stop album rotation animation when minimizing
            _albumRotationController.stop();
            
            // Add a subtle fade out animation before navigating back
            if (_fadeController.status != AnimationStatus.reverse) {
              await _fadeController.reverse();
            }
            
            // Navigate back to show mini player instead of exiting
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          } catch (e) {
            // Fallback: just navigate back if animation fails
            if (context.mounted) {
              Navigator.of(context).pop();
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Consumer<MusicService>(
          builder: (context, musicService, child) {
            final song = musicService.currentSong;
            if (song == null) {
              // If no song is playing, automatically close the full player
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              });
              return const SizedBox.shrink();
            }

            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanUpdate: (details) {
                // Track swipe direction during the gesture
              },
              onPanEnd: (details) {
                // Handle swipe gestures for the entire screen
                final velocity = details.velocity.pixelsPerSecond;
                final verticalVelocity = velocity.dy;
                final horizontalVelocity = velocity.dx;
                
                // Determine if this is primarily a vertical or horizontal swipe
                if (verticalVelocity.abs() > horizontalVelocity.abs()) {
                  // Vertical swipe - handle swipe down to minimize
                  if (verticalVelocity > 800) {
                    // Swipe down detected - minimize to mini player
                    Navigator.pop(context);
                  }
                } else {
                  // Horizontal swipe - handle previous/next song
                  if (horizontalVelocity > 500) {
                    // Swiping right - play previous song
                    musicService.playPrevious();
                    GlassNotification.show(
                      context,
                      message: 'Previous song',
                      icon: Icons.skip_previous_rounded,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    );
                  } else if (horizontalVelocity < -500) {
                    // Swiping left - play next song
                    musicService.playNext();
                    GlassNotification.show(
                      context,
                      message: 'Next song',
                      icon: Icons.skip_next_rounded,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                    );
                  }
                }
              },
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: Stack(
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Album Art
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Responsive album art size - balanced size
                          final screenHeight = MediaQuery.of(context).size.height;
                          final albumSize = screenHeight < 700 ? 260.0 : 300.0;
                          return _buildAlbumArt(song, size: albumSize);
                        },
                      ),

                      const SizedBox(height: 32),

                      // Song Info and Control Button Row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          children: [
                            // Song Info on the left
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    style: AppTheme.headlineMedium.copyWith(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(width: 16),
                            
                            // Pause/Play Button on the right
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
                          ],
                        ),
                      ),

                      const SizedBox(height: 4),

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

                      // Reduced spacing for better screen fit
                      const SizedBox(height: 20),

                      // Compact Lyrics Widget
                      const CompactLyricsWidget(
                        showTimestamps: false,
                      ),

                      // Reduced space for better screen fit
                      const SizedBox(height: 4),

                      // Bottom Control Bar moved to the very bottom
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Shuffle Button
                              Consumer<MusicService>(
                                builder: (context, musicService, child) {
                                  return _buildBottomControlButton(
                                    icon: musicService.isShuffleEnabled 
                                        ? Icons.shuffle_on_rounded 
                                        : Icons.shuffle_rounded,
                                    isActive: musicService.isShuffleEnabled,
                                    onPressed: () {
                                      musicService.toggleShuffle();
                                      GlassNotification.show(
                                        context,
                                        message: musicService.isShuffleEnabled ? 'Shuffle on' : 'Shuffle off',
                                        icon: Icons.shuffle_rounded,
                                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                      );
                                    },
                                  );
                                },
                              ),
                              // Favorite Button
                              Consumer<FavoritesService>(
                                builder: (context, favoritesService, child) {
                                  final isFavorite = favoritesService.isFavorite(song.id);
                                  return _buildBottomControlButton(
                                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                                    isActive: isFavorite,
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
                              // Repeat Button
                              Consumer<MusicService>(
                                builder: (context, musicService, child) {
                                  return _buildBottomControlButton(
                                    icon: musicService.isRepeatEnabled 
                                        ? Icons.repeat_one_rounded 
                                        : Icons.repeat_rounded,
                                    isActive: musicService.isRepeatEnabled,
                                    onPressed: () {
                                      musicService.toggleRepeat();
                                      GlassNotification.show(
                                        context,
                                        message: musicService.isRepeatEnabled ? 'Repeat on' : 'Repeat off',
                                        icon: Icons.repeat_rounded,
                                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ], // Close Stack
            ), // Close Container
            ), // Close GestureDetector
          );
        },
      ),
      ),
    );
  }
}
