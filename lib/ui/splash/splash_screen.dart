import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/modern_toast.dart';
import '../../core/services/auth_service.dart';
import '../../core/services/music_service.dart';
import '../../core/transitions/page_transitions.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _backgroundController;
  late AnimationController _swipeIndicatorController;
  bool _animationsComplete = false;

  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _textController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _swipeIndicatorController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _startAnimation();
    _monitorMusicScanning();
  }

  void _monitorMusicScanning() {
    // Listen to music service changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final musicService = context.read<MusicService>();
      
      // Add a listener to monitor progress
      void musicServiceListener() {
        if (mounted) {
          setState(() {
            // UI will automatically update through Consumer widgets
          });
        }
      }
      
      musicService.addListener(musicServiceListener);
      
      // Initial check
      musicServiceListener();
    });
  }

  void _startAnimation() async {
    // Start background animation
    _backgroundController.forward();
    
    // Delay then start logo animation
    await Future.delayed(const Duration(milliseconds: 500));
    _logoController.forward();
    
    // Delay then start text animation
    await Future.delayed(const Duration(milliseconds: 800));
    _textController.forward();
    
    // Wait for animations to complete, then show swipe indicator
    await Future.delayed(const Duration(milliseconds: 2000));
    setState(() {
      _animationsComplete = true;
    });
    
    // Start pulsing swipe indicator
    _swipeIndicatorController.repeat(reverse: true);
  }

  void _handleSwipeUp() async {
    if (!_animationsComplete) return;
    if (!mounted) return;
    
    final authService = context.read<AuthService>();
    final musicService = context.read<MusicService>();
    
    // Show a message if music scanning is still in progress
    if (!musicService.isBackgroundScanComplete && !musicService.isCacheLoaded) {
      ModernToast.showInfo(
        context,
        message: 'Music library is still loading. Continuing anyway...',
      );
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
    }
    
    if (authService.isAuthenticated) {
      // User is logged in, show welcome message and navigate to home
      ModernToast.showSuccess(
        context,
        message: 'Welcome back, ${authService.currentUser?.displayName ?? 'User'}!',
      );
      
      await Future.delayed(const Duration(milliseconds: 1000));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageTransitions.circleMorph(const HomeScreen()),
        );
      }
    } else {
      // User is not logged in, navigate to login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageTransitions.circleMorph(const LoginScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _backgroundController.dispose();
    _swipeIndicatorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: GestureDetector(
        onPanUpdate: (details) {
          // Detect swipe up gesture
          if (details.delta.dy < -10) {
            _handleSwipeUp();
          }
        },
        onTap: () {
          // Allow users to tap to navigate
          if (_animationsComplete) {
            _handleSwipeUp();
          }
        },
        child: AnimatedBackground(
          showParticles: true,
          showGradient: true,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoController.value,
                      child: GlowingOrb(
                        size: 120,
                        color: AppTheme.primaryColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // App Name
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _textController.value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - _textController.value)),
                        child: Column(
                          children: [
                            Text(
                              'Melody',
                              style: AppTheme.displayLarge.copyWith(
                                fontSize: 48,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                shadows: [
                                  Shadow(
                                    blurRadius: 20,
                                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Music Reimagined',
                              style: AppTheme.bodyLarge.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 18,
                                letterSpacing: 4,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 60),
                
                // Music Scanning Progress
                Consumer<MusicService>(
                  builder: (context, musicService, child) {
                    return AnimatedOpacity(
                      opacity: _animationsComplete ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.primaryColor.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  musicService.isBackgroundScanComplete 
                                      ? Icons.check_circle 
                                      : Icons.music_note,
                                  color: musicService.isBackgroundScanComplete 
                                      ? AppTheme.successColor 
                                      : AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  musicService.isBackgroundScanComplete 
                                      ? 'Music Library Ready' 
                                      : musicService.isCacheLoaded 
                                          ? 'Refreshing Library...' 
                                          : 'Scanning Device Music...',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${musicService.songs.length} songs found',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (!musicService.isBackgroundScanComplete) ...[
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                backgroundColor: AppTheme.backgroundColor.withValues(alpha: 0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Lottie Animation
                SizedBox(
                  height: 150,
                  width: 150,
                  child: Lottie.asset(
                    'assets/animations/music_play.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ).animate().fadeIn(delay: 1500.ms).scale(
                  begin: const Offset(0.8, 0.8),
                  curve: Curves.elasticOut,
                  duration: 800.ms,
                ),
                
                const SizedBox(height: 80),
                
                // Swipe up indicator (only shown after animations complete)
                if (_animationsComplete)
                  Consumer<MusicService>(
                    builder: (context, musicService, child) {
                      return AnimatedBuilder(
                        animation: _swipeIndicatorController,
                        builder: (context, child) {
                          return Opacity(
                            opacity: 0.4 + (0.6 * _swipeIndicatorController.value),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.keyboard_arrow_up,
                                  color: AppTheme.primaryColor,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  musicService.isBackgroundScanComplete || musicService.isCacheLoaded
                                      ? 'Swipe up to continue'
                                      : 'Swipe up to continue (scanning in background)',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'or tap anywhere',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondary.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
