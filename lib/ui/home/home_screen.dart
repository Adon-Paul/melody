import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/modern_button.dart';
import '../../core/widgets/mini_player.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/music_service.dart';
import '../../core/services/favorites_service.dart';
import '../../core/transitions/page_transitions.dart';
import '../device_music_page.dart';
import '../favorites_page.dart';
import '../spotify_login_page.dart';
import '../../core/demo/transition_demo_page.dart';
import '../../ui/auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // No need to call loadSongs() since MusicService auto-starts background scanning
    // Just let the background scan populate songs naturally
  }

  Future<void> _handleSignOut() async {
    final authService = context.read<AuthService>();
    await authService.signOut();
    
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageTransitions.circleMorph(const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default back behavior
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Show confirmation dialog before exiting app
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit App'),
              content: const Text('Are you sure you want to exit Melody?'),
              backgroundColor: AppTheme.surfaceColor,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Exit', style: TextStyle(color: AppTheme.primaryColor)),
                ),
              ],
            ),
          );
          
          if (shouldExit == true && context.mounted) {
            // Exit the app
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
        title: Text(
          'MELODY',
          style: AppTheme.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _handleSignOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Column(
              children: [
                // Main Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Welcome Header
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                            border: Border.all(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: AppTheme.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.music_note,
                                  size: 40,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Welcome to MELODY',
                                style: AppTheme.headlineMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your musical journey begins here',
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Music Status Card
                        Consumer<MusicService>(
                          builder: (context, musicService, child) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageTransitions.circleMorph(const DeviceMusicPage()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  border: Border.all(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.library_music,
                                          color: AppTheme.primaryColor,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Device Music',
                                            style: AppTheme.headlineMedium.copyWith(
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: AppTheme.textSecondary,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                  const SizedBox(height: 12),
                                  if (musicService.isLoading)
                                    Row(
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Scanning for music files...',
                                          style: AppTheme.bodyMedium.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    )
                                  else if (musicService.errorMessage != null)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: AppTheme.errorColor,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                musicService.errorMessage!,
                                                style: AppTheme.bodySmall.copyWith(
                                                  color: AppTheme.errorColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ModernButton(
                                          text: 'Retry',
                                          onPressed: () => musicService.loadSongs(),
                                          variant: ButtonVariant.outlined,
                                          iconData: Icons.refresh,
                                        ),
                                      ],
                                    )
                                  else
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: AppTheme.successColor,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${musicService.songs.length} songs found',
                                              style: AppTheme.bodyMedium.copyWith(
                                                color: AppTheme.successColor,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (musicService.songs.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          Text(
                                            'Recent songs:',
                                            style: AppTheme.bodySmall.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          ...musicService.songs.take(3).map((song) => Padding(
                                            padding: const EdgeInsets.only(bottom: 4),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.music_note,
                                                  size: 16,
                                                  color: AppTheme.textSecondary,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    song.title,
                                                    style: AppTheme.bodySmall.copyWith(
                                                      color: AppTheme.textSecondary,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                        ],
                                      ],
                                    ),
                                ],
                              ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Favorites Card
                        Consumer<FavoritesService>(
                          builder: (context, favoritesService, child) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageTransitions.circleMorph(const FavoritesPage()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  border: Border.all(
                                    color: Colors.red.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.favorite,
                                          color: Colors.red,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Favorites',
                                            style: AppTheme.headlineMedium.copyWith(
                                              color: AppTheme.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          color: AppTheme.textSecondary,
                                          size: 16,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          favoritesService.favorites.isNotEmpty 
                                              ? Icons.check_circle 
                                              : Icons.favorite_border,
                                          color: favoritesService.favorites.isNotEmpty 
                                              ? Colors.red 
                                              : AppTheme.textSecondary,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          favoritesService.favorites.isEmpty
                                              ? 'No favorite songs yet'
                                              : '${favoritesService.favorites.length} favorite songs',
                                          style: AppTheme.bodyMedium.copyWith(
                                            color: favoritesService.favorites.isNotEmpty 
                                                ? Colors.red 
                                                : AppTheme.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (favoritesService.favorites.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        'Recent favorites:',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...favoritesService.favorites.take(3).map((song) => Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.favorite,
                                              size: 16,
                                              color: Colors.red,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                song.title,
                                                style: AppTheme.bodySmall.copyWith(
                                                  color: AppTheme.textSecondary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Spotify Card
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageTransitions.circleMorph(const SpotifyLoginPage()),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceColor,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(
                                color: const Color(0xFF1DB954).withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1DB954).withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF1DB954),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.music_note,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Spotify Integration',
                                        style: AppTheme.headlineMedium.copyWith(
                                          color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      color: AppTheme.textSecondary,
                                      size: 16,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.cloud_sync,
                                      color: const Color(0xFF1DB954),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Connect to access millions of songs',
                                      style: AppTheme.bodyMedium.copyWith(
                                        color: const Color(0xFF1DB954),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Search tracks, playlists, and discover music',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: ModernButton(
                                text: 'Transitions',
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    PageTransitions.circleMorph(const TransitionDemoPage()),
                                  );
                                },
                                variant: ButtonVariant.filled,
                                iconData: Icons.animation,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ModernButton(
                                text: 'Refresh',
                                onPressed: () {
                                  context.read<MusicService>().loadSongs();
                                },
                                variant: ButtonVariant.outlined,
                                iconData: Icons.refresh,
                              ),
                            ),
                          ],
                        ),
                      ],
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
