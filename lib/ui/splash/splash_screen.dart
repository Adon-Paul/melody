import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/modern_toast.dart';
import '../../core/services/auth_service.dart';
import '../auth/login_screen.dart';
import '../../test_page.dart';

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
    
    final authService = context.read<AuthService>();
    
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
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TestPage(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    } else {
      // User is not logged in, navigate to login
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const LoginScreen(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          ),
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
                                    color: AppTheme.primaryColor.withOpacity(0.5),
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
                  AnimatedBuilder(
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
                              'Swipe up to continue',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'or tap anywhere',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.textSecondary.withOpacity(0.6),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
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
