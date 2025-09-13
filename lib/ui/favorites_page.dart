import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../core/theme/app_theme.dart';
import '../core/services/favorites_service.dart';
import '../core/services/music_service.dart';
import '../core/services/music_player_navigation.dart';
import '../core/widgets/mini_player.dart';
import '../core/widgets/glass_notification.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  Widget _buildAlbumArt(Song song, {double size = 60}) {
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

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Widget _buildFavoriteTile(BuildContext context, Song song) {
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
              leading: _buildAlbumArt(song, size: 60),
              title: Text(
                song.title,
                style: AppTheme.titleMedium.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    song.artist,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(song.duration),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.favorite,
                        size: 16,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
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
                        size: 24,
                      ),
                      onPressed: () => _playFavoriteSong(context, song),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.errorColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.favorite_border,
                        color: AppTheme.errorColor,
                        size: 20,
                      ),
                      onPressed: () => _removeFavorite(context, song),
                    ),
                  ),
                ],
              ),
              onTap: () => _playFavoriteSong(context, song),
            ),
          ),
        ),
      ),
    );
  }

  void _playFavoriteSong(BuildContext context, Song song) async {
    final musicService = context.read<MusicService>();
    final favoritesService = context.read<FavoritesService>();
    
    // Get all favorite songs as the playlist
    final favoritesSongs = favoritesService.favorites;
    
    // Find the index of the selected song in the favorites list
    final songIndex = favoritesSongs.indexWhere((favSong) => favSong.id == song.id);
    
    if (songIndex != -1) {
      // Play from the favorites playlist starting at the selected song
      await musicService.playFromPlaylist(favoritesSongs, songIndex, userInitiated: true);
    } else {
      // Fallback to single song play if not found in favorites
      await musicService.playUserSelectedSong(song);
    }
    
    // Auto-navigate to full music player for user-initiated plays
    if (context.mounted) {
      MusicPlayerNavigation.showFullPlayerOnPlay(context);
    }
    
    if (context.mounted) {
      GlassNotification.show(
        context,
        message: 'Now playing: ${song.title}',
        icon: Icons.play_arrow_rounded,
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
      );
    }
  }

  void _removeFavorite(BuildContext context, Song song) {
    final favoritesService = context.read<FavoritesService>();
    favoritesService.removeFavorite(song.id);
    
    GlassNotification.show(
      context,
      message: 'Removed from favorites',
      icon: Icons.favorite_border,
      backgroundColor: AppTheme.errorColor.withValues(alpha: 0.2),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        // Handle cleanup when navigating back from favorites
        if (didPop) {
          // Clean up any listeners or animations if needed
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Stack(
        children: [
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
                              'Favorites',
                              style: AppTheme.headlineMedium.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Consumer<FavoritesService>(
                            builder: (context, favoritesService, child) {
                              return favoritesService.favorites.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear_all_rounded,
                                        color: AppTheme.errorColor,
                                      ),
                                      onPressed: () => _showClearAllDialog(context),
                                    )
                                  : const SizedBox(width: 48);
                            },
                          ),
                        ],
                      ),
                      
                      // Results Counter
                      Consumer<FavoritesService>(
                        builder: (context, favoritesService, child) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              '${favoritesService.favorites.length} favorite songs',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: Consumer<FavoritesService>(
                    builder: (context, favoritesService, child) {
                      if (favoritesService.favorites.isEmpty) {
                        return Center(
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
                                  Icons.favorite_border_rounded,
                                  size: 64,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No favorite songs yet',
                                  style: AppTheme.titleMedium.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the heart icon on any song to add it to your favorites',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return Scrollbar(
                        thumbVisibility: true,
                        trackVisibility: true,
                        radius: const Radius.circular(8),
                        thickness: 8,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: favoritesService.favorites.length,
                          itemBuilder: (context, index) {
                            return _buildFavoriteTile(
                              context,
                              favoritesService.favorites[index],
                            );
                          },
                        ),
                      );
                    },
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

  void _showClearAllDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Clear All Favorites',
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to remove all songs from your favorites? This action cannot be undone.',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                context.read<FavoritesService>().clearFavorites();
                Navigator.of(context).pop();
                
                GlassNotification.show(
                  context,
                  message: 'All favorites cleared',
                  icon: Icons.clear_all_rounded,
                  backgroundColor: AppTheme.errorColor.withValues(alpha: 0.2),
                );
              },
              child: Text(
                'Clear All',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
