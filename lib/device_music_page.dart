import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'core/theme/app_theme.dart';
import 'core/widgets/animated_background.dart';
import 'core/widgets/glass_notification.dart';
import 'core/services/music_service.dart';
import 'core/services/favorites_service.dart';
import 'ui/full_music_player_page.dart';

class DeviceMusicPage extends StatefulWidget {
  const DeviceMusicPage({super.key});

  @override
  State<DeviceMusicPage> createState() => _DeviceMusicPageState();
}

class _DeviceMusicPageState extends State<DeviceMusicPage> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  Timer? _statusUpdateTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    
    // Animation for smooth loading transitions
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.easeIn),
    );
    
    // Start animation immediately
    _loadingController.forward();
    
    // Periodic status updates for real-time feedback
    _statusUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          // Just trigger rebuild to update status
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _loadingController.dispose();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicService>(
      builder: (context, musicService, child) {
        // Always filter songs - even if list is empty, it won't cause delays
        final allSongs = musicService.getAvailableSongs();
        final filteredSongs = _searchQuery.isEmpty
            ? allSongs
            : allSongs.where((song) {
                return song.title.toLowerCase().contains(_searchQuery) ||
                       song.artist.toLowerCase().contains(_searchQuery);
              }).toList();

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: Stack(
              children: [
                const AnimatedBackground(),
                SafeArea(
                  child: Column(
                    children: [
                      // Header - Always shows immediately
                      _buildHeader(musicService, allSongs, filteredSongs),
                      
                      // Content Area - Shows immediately with loading state if needed
                      Expanded(
                        child: _buildContent(filteredSongs, musicService),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(MusicService musicService, List<Song> allSongs, List<Song> filteredSongs) {
    return Container(
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
                icon: Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.primaryColor,
                ),
                onPressed: () async {
                  // Quick refresh without blocking UI
                  musicService.refreshSongs();
                  GlassNotification.show(
                    context,
                    message: 'Refreshing music library...',
                    icon: Icons.refresh,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search Bar - Always available
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.3),
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
          
          // Stats Row - Shows real-time status
          _buildStatsRow(musicService, allSongs, filteredSongs),
        ],
      ),
    );
  }

  Widget _buildStatsRow(MusicService musicService, List<Song> allSongs, List<Song> filteredSongs) {
    String statusText;
    IconData statusIcon;
    Color statusColor;
    
    if (musicService.isBackgroundScanComplete) {
      statusText = 'Ready';
      statusIcon = Icons.check_circle_rounded;
      statusColor = Colors.green;
    } else if (musicService.isCacheLoaded) {
      statusText = 'Loading...';
      statusIcon = Icons.hourglass_empty_rounded;
      statusColor = Colors.orange;
    } else {
      statusText = 'Scanning...';
      statusIcon = Icons.search_rounded;
      statusColor = AppTheme.primaryColor;
    }
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard(
          'Total Songs',
          '${allSongs.length}',
          Icons.music_note_rounded,
          AppTheme.primaryColor,
        ),
        _buildStatCard(
          'Filtered',
          '${filteredSongs.length}',
          Icons.filter_list_rounded,
          AppTheme.primaryColor,
        ),
        _buildStatCard(
          'Status',
          statusText,
          statusIcon,
          statusColor,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
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

  Widget _buildContent(List<Song> songs, MusicService musicService) {
    // Show content immediately regardless of loading state
    if (songs.isEmpty) {
      return _buildEmptyState(musicService);
    }
    
    return _buildMusicList(songs, musicService);
  }

  Widget _buildEmptyState(MusicService musicService) {
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
              style: AppTheme.titleMedium.copyWith(
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

    // Show different messages based on scanning state
    String message;
    String subMessage;
    IconData icon;
    
    if (musicService.isBackgroundScanComplete) {
      if (_searchQuery.isNotEmpty) {
        message = 'No matching songs';
        subMessage = 'Try a different search term';
        icon = Icons.search_off_rounded;
      } else {
        message = 'No music found';
        subMessage = 'Add some music files to your device';
        icon = Icons.music_off_rounded;
      }
    } else {
      message = 'Scanning for music...';
      subMessage = 'Please wait while we find your music files';
      icon = Icons.search_rounded;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(seconds: 2),
            builder: (context, value, child) {
              return Transform.rotate(
                angle: value * 2 * 3.14159,
                child: Icon(
                  icon,
                  size: 64,
                  color: AppTheme.textSecondary,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.titleMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMusicList(List<Song> songs, MusicService musicService) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: songs.length,
      // Use itemExtent for better performance
      itemExtent: 80,
      itemBuilder: (context, index) {
        final song = songs[index];
        final isCurrentSong = musicService.currentSong?.id == song.id;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isCurrentSong
                ? AppTheme.primaryColor.withOpacity(0.1)
                : AppTheme.surfaceColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrentSong
                  ? AppTheme.primaryColor.withOpacity(0.3)
                  : AppTheme.surfaceColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.primaryColor.withOpacity(0.1),
              ),
              child: song.albumArt != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        song.albumArt!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Icon(
                      Icons.music_note_rounded,
                      color: AppTheme.primaryColor,
                    ),
            ),
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
            trailing: Consumer<FavoritesService>(
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
            ),
            onTap: () {
              // Play the song
              musicService.playSong(song);
              
              // Navigate to full player
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FullMusicPlayerPage(),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
