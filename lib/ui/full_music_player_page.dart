import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../core/theme/app_theme.dart';
import '../core/services/music_service.dart';
import '../core/services/favorites_service.dart';
import '../core/services/lyrics_service.dart';
import '../core/widgets/animated_background.dart';
import '../core/widgets/glass_notification.dart';

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
  bool _isDraggingSeek = false;
  bool _lyricsMinimized = false;
  Duration _seekPosition = Duration.zero;

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
    _fadeController.forward();
    
    // Start album rotation if playing
    final musicService = context.read<MusicService>();
    if (musicService.isPlaying) {
      _albumRotationController.repeat();
    }

    // Listen for song changes to update lyrics
    musicService.addListener(_onSongChanged);

    // Initialize lyrics service and fetch lyrics for current song
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLyrics();
    });
  }

  void _onSongChanged() {
    final musicService = context.read<MusicService>();
    if (musicService.currentSong != null) {
      _initializeLyrics();
    }
  }

  @override
  void dispose() {
    _albumRotationController.dispose();
    _fadeController.dispose();
    _lyricsController.dispose();
    super.dispose();
  }

  void _initializeLyrics() async {
    final musicService = context.read<MusicService>();
    final lyricsService = context.read<LyricsService>();
    
    await lyricsService.initialize();
    
    if (musicService.currentSong != null) {
      lyricsService.fetchLyrics(
        musicService.currentSong!.artist,
        musicService.currentSong!.title,
      );
    }
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

  Widget _buildLyricsBox(MusicService musicService) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: _lyricsMinimized ? 60 : 200,
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
                  AppTheme.primaryColor.withOpacity(0.2),
                  AppTheme.accentColor.withOpacity(0.15),
                  AppTheme.primaryColor.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.8),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Lyrics',
                        style: AppTheme.titleMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _toggleLyricsMinimize,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            _lyricsMinimized ? Icons.expand_more_rounded : Icons.expand_less_rounded,
                            color: Colors.white.withOpacity(0.8),
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
                      child: Consumer<LyricsService>(
                        builder: (context, lyricsService, child) {
                          if (lyricsService.isLoading) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation(Colors.white.withOpacity(0.8)),
                                    strokeWidth: 3,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Loading lyrics...',
                                    style: AppTheme.bodyMedium.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          if (lyricsService.error != null) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Icon(
                                      Icons.lyrics_outlined,
                                      size: 32,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Lyrics not available',
                                    style: AppTheme.titleMedium.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    lyricsService.error!,
                                    style: AppTheme.bodySmall.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }

                          if (lyricsService.currentLyrics == null || lyricsService.currentLyrics!.lines.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(50),
                                    ),
                                    child: Icon(
                                      Icons.music_note_rounded,
                                      size: 32,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No lyrics found',
                                    style: AppTheme.titleMedium.copyWith(
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Enjoy the music without lyrics',
                                    style: AppTheme.bodySmall.copyWith(
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          }

                          // Update current time for lyrics synchronization
                          lyricsService.updateCurrentTime(musicService.position.inSeconds.toDouble());

                          // Show lyrics with current line highlighting
                          return ListView.builder(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: lyricsService.currentLyrics!.lines.length,
                            itemBuilder: (context, index) {
                              final lyric = lyricsService.currentLyrics!.lines[index];
                              final isCurrentLine = lyricsService.currentLineIndex == index;
                              
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                decoration: isCurrentLine ? BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.25),
                                      Colors.white.withOpacity(0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.4),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ) : null,
                                child: Text(
                                  lyric.text,
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: isCurrentLine 
                                        ? Colors.white 
                                        : Colors.white.withOpacity(0.8),
                                    fontWeight: isCurrentLine ? FontWeight.w600 : FontWeight.normal,
                                    fontSize: isCurrentLine ? 15 : 14,
                                    shadows: isCurrentLine ? [
                                      Shadow(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ] : null,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          );
                        },
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
                                        backgroundColor: AppTheme.surfaceColor.withOpacity(0.2),
                                      );
                                    } else {
                                      favoritesService.addFavorite(song);
                                      GlassNotification.show(
                                        context,
                                        message: 'Added to favorites',
                                        icon: Icons.favorite,
                                        backgroundColor: Colors.red.withOpacity(0.2),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Album Art
                      _buildAlbumArt(song, size: 280),

                      const SizedBox(height: 40),

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

                      const SizedBox(height: 40),

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
                                inactiveTrackColor: AppTheme.textSecondary.withOpacity(0.3),
                                thumbColor: AppTheme.primaryColor,
                                overlayColor: AppTheme.primaryColor.withOpacity(0.2),
                              ),
                              child: Slider(
                                value: _isDraggingSeek 
                                    ? _seekPosition.inMilliseconds.toDouble()
                                    : musicService.position.inMilliseconds.toDouble(),
                                min: 0,
                                max: musicService.duration.inMilliseconds.toDouble(),
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

                      const SizedBox(height: 30),

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
                                      ? AppTheme.surfaceColor.withOpacity(0.2)
                                      : AppTheme.primaryColor.withOpacity(0.2),
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

                      const SizedBox(height: 30),

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

                      const SizedBox(height: 30),

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
                                  inactiveTrackColor: AppTheme.textSecondary.withOpacity(0.3),
                                  thumbColor: AppTheme.primaryColor,
                                  overlayColor: AppTheme.primaryColor.withOpacity(0.2),
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
