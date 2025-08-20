import 'package:flutter/material.dart';
import 'dart:math' as math;

// ===== ENHANCED SLIDE TRANSITIONS =====

/// Enhanced slide right transition with scale and parallax effect
class MorphSlideRightRoute extends PageRouteBuilder {
  final Widget page;
  
  MorphSlideRightRoute({required this.page})
    : super(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Primary slide animation with custom curve
            final slideAnimation = Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ));

            // Scale animation for depth
            final scaleAnimation = Tween<double>(
              begin: 0.92,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ));

            // Previous page parallax effect
            final exitSlideAnimation = Tween<Offset>(
              begin: Offset.zero,
              end: const Offset(-0.3, 0.0),
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeInCubic,
            ));

            final exitFadeAnimation = Tween<double>(
              begin: 1.0,
              end: 0.5,
            ).animate(CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeIn,
            ));

            return Stack(
              children: [
                // Exiting page with parallax
                SlideTransition(
                  position: exitSlideAnimation,
                  child: FadeTransition(
                    opacity: exitFadeAnimation,
                    child: const SizedBox.expand(), // Placeholder for previous page
                  ),
                ),
                // Entering page
                SlideTransition(
                  position: slideAnimation,
                  child: ScaleTransition(
                    scale: scaleAnimation,
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
}

/// Enhanced slide left transition with rotation
class MorphSlideLeftRoute extends PageRouteBuilder {
  final Widget page;
  
  MorphSlideLeftRoute({required this.page})
    : super(
          transitionDuration: const Duration(milliseconds: 450),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ));

            final scaleAnimation = Tween<double>(
              begin: 0.95,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ));

            final rotationAnimation = Tween<double>(
              begin: -0.01,
              end: 0.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            return SlideTransition(
              position: slideAnimation,
              child: Transform.rotate(
                angle: rotationAnimation.value,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: child,
                ),
              ),
            );
          },
        );
}

/// Elastic slide up with bounce effect
class ElasticSlideUpRoute extends PageRouteBuilder {
  final Widget page;
  
  ElasticSlideUpRoute({required this.page})
    : super(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideAnimation = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            ));

            final rotationAnimation = Tween<double>(
              begin: 0.03,
              end: 0.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            final fadeAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
            ));

            return SlideTransition(
              position: slideAnimation,
              child: FadeTransition(
                opacity: fadeAnimation,
                child: Transform.rotate(
                  angle: rotationAnimation.value,
                  child: child,
                ),
              ),
            );
          },
        );
}

// ===== CREATIVE MORPH TRANSITIONS =====

/// 3D Flip transition
class FlipRoute extends PageRouteBuilder {
  final Widget page;
  final bool isHorizontal;
  
  FlipRoute({required this.page, this.isHorizontal = true})
    : super(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final flipAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutSine,
            ));

            return AnimatedBuilder(
              animation: flipAnimation,
              builder: (context, child) {
                final isShowingFront = flipAnimation.value < 0.5;
                
                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.001)
                    ..rotateY(isHorizontal ? flipAnimation.value * math.pi : 0)
                    ..rotateX(isHorizontal ? 0 : flipAnimation.value * math.pi),
                  child: isShowingFront
                      ? const SizedBox.expand() // Previous page placeholder
                      : child,
                );
              },
              child: child,
            );
          },
        );
}

/// Morphing circle transition
class CircleMorphRoute extends PageRouteBuilder {
  final Widget page;
  
  CircleMorphRoute({required this.page})
    : super(
          transitionDuration: const Duration(milliseconds: 700),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final expandAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ));

            return AnimatedBuilder(
              animation: expandAnimation,
              builder: (context, child) {
                final screenSize = MediaQuery.of(context).size;
                final maxRadius = math.sqrt(screenSize.width * screenSize.width + 
                                         screenSize.height * screenSize.height);
                
                return ClipOval(
                  clipper: CircleRevealClipper(
                    fraction: expandAnimation.value,
                    centerAlignment: Alignment.center,
                    minRadius: 0,
                    maxRadius: maxRadius,
                  ),
                  child: child,
                );
              },
              child: child,
            );
          },
        );
}

/// Liquid morph transition
class LiquidMorphRoute extends PageRouteBuilder {
  final Widget page;
  
  LiquidMorphRoute({required this.page})
    : super(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final waveAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ));

            return AnimatedBuilder(
              animation: waveAnimation,
              builder: (context, child) {
                return ClipPath(
                  clipper: WaveClipper(animationValue: waveAnimation.value),
                  child: child,
                );
              },
              child: child,
            );
          },
        );
}

/// Particle dissolve transition
class ParticleDissolveRoute extends PageRouteBuilder {
  final Widget page;
  
  ParticleDissolveRoute({required this.page})
    : super(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final dissolveAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutQuart,
            ));

            final scaleAnimation = Tween<double>(
              begin: 1.1,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));

            return AnimatedBuilder(
              animation: dissolveAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: scaleAnimation.value,
                  child: Opacity(
                    opacity: dissolveAnimation.value,
                    child: CustomPaint(
                      painter: ParticlePainter(progress: dissolveAnimation.value),
                      child: child,
                    ),
                  ),
                );
              },
              child: child,
            );
          },
        );
}

/// Glitch transition effect
class GlitchRoute extends PageRouteBuilder {
  final Widget page;
  
  GlitchRoute({required this.page})
    : super(
          transitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final glitchAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.elasticInOut,
            ));

            return AnimatedBuilder(
              animation: glitchAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Red channel
                    Transform.translate(
                      offset: Offset(
                        math.sin(glitchAnimation.value * 20) * 3,
                        0,
                      ),
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.red,
                          BlendMode.screen,
                        ),
                        child: child,
                      ),
                    ),
                    // Green channel
                    Transform.translate(
                      offset: Offset(
                        -math.sin(glitchAnimation.value * 15) * 2,
                        math.cos(glitchAnimation.value * 10) * 1,
                      ),
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.green,
                          BlendMode.screen,
                        ),
                        child: child,
                      ),
                    ),
                    // Blue channel
                    Transform.translate(
                      offset: Offset(
                        math.cos(glitchAnimation.value * 18) * 2,
                        -math.sin(glitchAnimation.value * 12) * 2,
                      ),
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(
                          Colors.blue,
                          BlendMode.screen,
                        ),
                        child: child,
                      ),
                    ),
                    // Normal child on top
                    Opacity(
                      opacity: 1.0 - (glitchAnimation.value * 0.3),
                      child: child,
                    ),
                  ],
                );
              },
              child: child,
            );
          },
        );
}

// ===== CUSTOM CLIPPERS =====

class CircleRevealClipper extends CustomClipper<Rect> {
  final double fraction;
  final Alignment centerAlignment;
  final double minRadius;
  final double maxRadius;

  CircleRevealClipper({
    required this.fraction,
    required this.centerAlignment,
    required this.minRadius,
    required this.maxRadius,
  });

  @override
  Rect getClip(Size size) {
    final center = centerAlignment.resolve(TextDirection.ltr).withinRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    final radius = minRadius + (maxRadius - minRadius) * fraction;
    
    return Rect.fromCircle(center: center, radius: radius);
  }

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => true;
}

class WaveClipper extends CustomClipper<Path> {
  final double animationValue;

  WaveClipper({required this.animationValue});

  @override
  Path getClip(Size size) {
    final path = Path();
    final waveHeight = size.height * 0.2;
    final waveFrequency = 3.0;
    
    // Start from bottom left
    path.moveTo(0, size.height);
    
    // Create wave based on animation progress
    for (double x = 0; x <= size.width; x++) {
      final y = size.height - (size.height * animationValue) + 
                math.sin((x / size.width * waveFrequency * math.pi) + 
                        (animationValue * math.pi * 2)) * waveHeight * (1 - animationValue);
      path.lineTo(x, y);
    }
    
    // Complete the path
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

class ParticlePainter extends CustomPainter {
  final double progress;

  ParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 1;

    final random = math.Random(42); // Fixed seed for consistent animation
    
    for (int i = 0; i < 50; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final opacity = (progress * random.nextDouble()).clamp(0.0, 1.0);
      
      paint.color = Colors.white.withOpacity(opacity * 0.3);
      canvas.drawCircle(
        Offset(x, y),
        random.nextDouble() * 3 + 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// ===== UTILITY CLASS FOR EASY ACCESS =====

class PageTransitions {
  // Enhanced versions of existing transitions
  static PageRouteBuilder slideRight(Widget page) => MorphSlideRightRoute(page: page);
  static PageRouteBuilder slideLeft(Widget page) => MorphSlideLeftRoute(page: page);
  static PageRouteBuilder slideUp(Widget page) => ElasticSlideUpRoute(page: page);
  
  // Creative new transitions
  static PageRouteBuilder flip(Widget page, {bool horizontal = true}) => 
      FlipRoute(page: page, isHorizontal: horizontal);
  static PageRouteBuilder circleMorph(Widget page) => CircleMorphRoute(page: page);
  static PageRouteBuilder liquidMorph(Widget page) => LiquidMorphRoute(page: page);
  static PageRouteBuilder particleDissolve(Widget page) => ParticleDissolveRoute(page: page);
  static PageRouteBuilder glitch(Widget page) => GlitchRoute(page: page);
}
