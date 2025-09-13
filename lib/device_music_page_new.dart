import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'core/theme/app_theme.dart';
import 'core/widgets/animated_background.dart';
import 'core/services/music_service.dart';
import 'core/services/favorites_service.dart';
import 'core/transitions/page_transitions.dart';
import 'ui/full_music_player_page.dart';

class DeviceMusicPage extends StatefulWidget {
  const DeviceMusicPage({super.key});

  @override
  State<DeviceMusicPage> createState() => _DeviceMusicPageState();
}

class _DeviceMusicPageState extends State<DeviceMusicPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    if (query == _searchQuery) return; // Avoid unnecessary updates
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Set searching state immediately
    setState(() {
      _isSearching = query.isNotEmpty;
    });
    
    // Debounce the actual search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = query;
        });
      }
    });
  }

  List<Song> _getFilteredSongs(List<Song> allSongs) {
    if (_searchQuery.isEmpty) return allSongs;
    
    // Use cached filtered results to avoid recomputing
    return allSongs.where((song) {
      return song.title.toLowerCase().contains(_searchQuery) ||
             song.artist.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicService>(
      builder: (context, musicService, child) {
        // Use optimized filtering
        final filteredSongs = _getFilteredSongs(musicService.songs);

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
                              // Refresh Button
                              IconButton(
                                icon: _isSearching
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.refresh_rounded,
                                        color: AppTheme.primaryColor,
                                      ),
                                onPressed: _isSearching
                                    ? null
                                    : () async {
                                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                                        await musicService.refreshSongs();
                                        if (mounted) {
                                          scaffoldMessenger.showSnackBar(
                                            SnackBar(
                                              content: const Text('Music library refreshed'),
                                              backgroundColor: AppTheme.primaryColor,
                                              duration: const Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Search Bar
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search music...',
                                hintStyle: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: AppTheme.textSecondary,
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
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard(
                                'Total Songs',
                                '${musicService.songs.length}',
                                Icons.music_note_rounded,
                              ),
                              _buildStatCard(
                                'Filtered',
                                '${filteredSongs.length}',
                                Icons.filter_list_rounded,
                              ),
                              _buildStatCard(
                                'Status',
                                musicService.isBackgroundScanComplete
                                    ? 'Ready'
                                    : musicService.isCacheLoaded
                                        ? 'Loading...'
                                        : 'Scanning...',
                                musicService.isBackgroundScanComplete
                                    ? Icons.check_circle_rounded
                                    : Icons.hourglass_empty_rounded,
                                isAnimated: !musicService.isBackgroundScanComplete,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Music List
                    Expanded(
                      child: _buildMusicList(filteredSongs, musicService),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {bool isAnimated = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          isAnimated
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryColor),
                  ),
                )
              : Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicList(List<Song> songs, MusicService musicService) {
    if (musicService.isLoading && songs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (musicService.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading music',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              musicService.errorMessage!,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => musicService.refreshSongs(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (songs.isEmpty && !musicService.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off_rounded,
              size: 64,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No matching songs' : 'No music found',
              style: AppTheme.titleLarge.copyWith(
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Add some music files to your device',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: songs.length,
      // Performance optimizations
      cacheExtent: 500, // Cache more items for smoother scrolling
      addAutomaticKeepAlives: false, // Don't keep all items alive
      addRepaintBoundaries: true, // Better performance for complex items
      itemBuilder: (context, index) {
        final song = songs[index];
        return _buildSongTile(song, songs, musicService, index);
      },
    );
  }

  Widget _buildSongTile(Song song, List<Song> songs, MusicService musicService, int index) {
    final isCurrentSong = musicService.currentSong?.id == song.id;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCurrentSong
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppTheme.surfaceColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentSong
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppTheme.surfaceColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: ListTile(
        leading: _buildAlbumArt(song),
        title: Text(
          song.title,
          style: AppTheme.bodyMedium.copyWith(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          song.artist,
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _buildTrailing(song, isCurrentSong, musicService),
        onTap: () {
          // Play the song using playFromPlaylist
          final songIndex = songs.indexOf(song);
          musicService.playFromPlaylist(songs, songIndex);
          
          // Navigate to full player
          Navigator.push(
            context,
            PageTransitions.circleMorph(const FullMusicPlayerPage()),
          );
        },
      ),
    );
  }

  Widget _buildAlbumArt(Song song) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
      ),
      child: song.albumArt != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                song.albumArt!,
                fit: BoxFit.cover,
                // Performance optimization: cache the image
                cacheHeight: 50,
                cacheWidth: 50,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.music_note_rounded,
                    color: AppTheme.primaryColor,
                  );
                },
              ),
            )
          : Icon(
              Icons.music_note_rounded,
              color: AppTheme.primaryColor,
            ),
    );
  }

  Widget _buildTrailing(Song song, bool isCurrentSong, MusicService musicService) {
    return Consumer<FavoritesService>(
      builder: (context, favoritesService, child) {
        final isFavorite = favoritesService.isFavorite(song.id);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCurrentSong && musicService.isPlaying)
              Container(
                margin: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.equalizer_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? Colors.red : AppTheme.textSecondary,
                size: 20,
              ),
              onPressed: () {
                if (isFavorite) {
                  favoritesService.removeFavorite(song.id);
                } else {
                  favoritesService.addFavorite(song);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
