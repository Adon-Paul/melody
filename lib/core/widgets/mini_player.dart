import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../services/music_service.dart';
import 'glass_notification.dart';
import '../../ui/full_music_player_page.dart';
import '../transitions/advanced_transitions.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildAlbumArt(Song song, {double size = 48}) {
    if (song.albumArt != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
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
    }
    return _buildGeneratedAlbumArt(song, size);
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          song.artist.isNotEmpty ? song.artist[0].toUpperCase() : '♪',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.3,
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

  void _showPlaybackSettings(BuildContext context, MusicService musicService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
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
            Text(
              'Playback Settings',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            // Shuffle Toggle
            ListTile(
              leading: Icon(
                Icons.shuffle_rounded,
                color: musicService.isShuffleEnabled 
                  ? AppTheme.primaryColor 
                  : AppTheme.textSecondary,
              ),
              title: Text(
                'Shuffle',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              trailing: Switch(
                value: musicService.isShuffleEnabled,
                onChanged: (value) {
                  musicService.toggleShuffle();
                  GlassNotification.show(
                    context,
                    message: 'Shuffle ${value ? 'enabled' : 'disabled'}',
                    icon: Icons.shuffle_rounded,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  );
                },
                activeThumbColor: AppTheme.primaryColor,
              ),
              onTap: () {
                musicService.toggleShuffle();
                GlassNotification.show(
                  context,
                  message: 'Shuffle ${musicService.isShuffleEnabled ? 'enabled' : 'disabled'}',
                  icon: Icons.shuffle_rounded,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                );
              },
            ),
            
            // Repeat Toggle
            ListTile(
              leading: Icon(
                Icons.repeat_rounded,
                color: musicService.isRepeatEnabled 
                  ? AppTheme.primaryColor 
                  : AppTheme.textSecondary,
              ),
              title: Text(
                'Repeat',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              trailing: Switch(
                value: musicService.isRepeatEnabled,
                onChanged: (value) {
                  musicService.toggleRepeat();
                  GlassNotification.show(
                    context,
                    message: 'Repeat ${value ? 'enabled' : 'disabled'}',
                    icon: Icons.repeat_rounded,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  );
                },
                activeThumbColor: AppTheme.primaryColor,
              ),
              onTap: () {
                musicService.toggleRepeat();
                GlassNotification.show(
                  context,
                  message: 'Repeat ${musicService.isRepeatEnabled ? 'enabled' : 'disabled'}',
                  icon: Icons.repeat_rounded,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                );
              },
            ),
            
            // Auto-play Next Toggle
            ListTile(
              leading: Icon(
                Icons.skip_next_rounded,
                color: musicService.autoPlayNext 
                  ? AppTheme.primaryColor 
                  : AppTheme.textSecondary,
              ),
              title: Text(
                'Auto-play Next',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              trailing: Switch(
                value: musicService.autoPlayNext,
                onChanged: (value) {
                  musicService.toggleAutoPlayNext();
                  GlassNotification.show(
                    context,
                    message: 'Auto-play ${value ? 'enabled' : 'disabled'}',
                    icon: Icons.skip_next_rounded,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                  );
                },
                activeThumbColor: AppTheme.primaryColor,
              ),
              onTap: () {
                musicService.toggleAutoPlayNext();
                GlassNotification.show(
                  context,
                  message: 'Auto-play ${musicService.autoPlayNext ? 'enabled' : 'disabled'}',
                  icon: Icons.skip_next_rounded,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                );
              },
            ),
            
            const SizedBox(height: 16),
            
            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: AppTheme.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicService>(
      builder: (context, musicService, child) {
        // Only show mini player when there's a current song
        if (musicService.currentSong == null) {
          return const SizedBox.shrink();
        }

        final song = musicService.currentSong!;

        return Container(
          height: 80,
          margin: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () {
              context.pushMorph(const FullMusicPlayerPage());
            },
            onLongPress: () {
              _showPlaybackSettings(context, musicService);
            },
            child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      // Album Art
                      _buildAlbumArt(song, size: 48),
                      
                      const SizedBox(width: 12),
                      
                      // Song Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              song.title,
                              style: AppTheme.titleMedium.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              song.artist,
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 8),
                      
                      // Progress Indicator (small)
                      if (musicService.duration.inMilliseconds > 0)
                        SizedBox(
                          width: 40,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: musicService.progress,
                                strokeWidth: 2,
                                backgroundColor: AppTheme.textSecondary.withValues(alpha: 0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDuration(musicService.position),
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(width: 8),
                      
                      // Previous Button
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          onPressed: () async {
                            await musicService.playPrevious();
                          },
                          icon: Icon(
                            Icons.skip_previous_rounded,
                            color: AppTheme.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      
                      // Play/Pause Button
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {
                            final isCurrentlyPlaying = musicService.isPlaying;
                            musicService.togglePlayPause();
                            
                            // Show appropriate notification
                            if (isCurrentlyPlaying) {
                              GlassNotification.show(
                                context,
                                message: 'Paused',
                                icon: Icons.pause_rounded,
                                backgroundColor: AppTheme.surfaceColor.withValues(alpha: 0.2),
                              );
                            } else {
                              GlassNotification.show(
                                context,
                                message: 'Playing: ${song.title}',
                                icon: Icons.play_arrow_rounded,
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                              );
                            }
                          },
                          icon: Icon(
                            musicService.isPlaying 
                              ? Icons.pause_rounded 
                              : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 4),
                      
                      // Next Button
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: IconButton(
                          onPressed: () async {
                            await musicService.playNext();
                          },
                          icon: Icon(
                            Icons.skip_next_rounded,
                            color: AppTheme.textPrimary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),
        );
      },
    );
  }
}
