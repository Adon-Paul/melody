import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Fast and smooth circle morph transition - the only transition used in the app
class CircleMorphRoute extends PageRouteBuilder {
  final Widget page;
  
  CircleMorphRoute({required this.page})
    : super(
          transitionDuration: const Duration(milliseconds: 800), // Increased for better visibility
          reverseTransitionDuration: const Duration(milliseconds: 600),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final expandAnimation = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic, // Smoother, more visible curve
            ));

            return AnimatedBuilder(
              animation: expandAnimation,
              builder: (context, child) {
                final screenSize = MediaQuery.of(context).size;
                final maxRadius = math.sqrt(screenSize.width * screenSize.width + 
                                         screenSize.height * screenSize.height);
                
                // Add subtle scale effect for better visibility
                final scaleValue = 0.95 + (expandAnimation.value * 0.05);
                
                return Transform.scale(
                  scale: scaleValue,
                  child: ClipOval(
                    clipper: CircleRevealClipper(
                      fraction: expandAnimation.value,
                      centerAlignment: Alignment.center,
                      minRadius: 0,
                      maxRadius: maxRadius,
                    ),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
        );
}

/// Custom clipper for circle reveal effect
class CircleRevealClipper extends CustomClipper<Rect> {
  final double fraction;
  final Alignment centerAlignment;
  final double minRadius;
  final double maxRadius;

  CircleRevealClipper({
    required this.fraction,
    this.centerAlignment = Alignment.center,
    this.minRadius = 0,
    required this.maxRadius,
  });

  @override
  Rect getClip(Size size) {
    final center = centerAlignment.alongSize(size);
    final radius = minRadius + (maxRadius - minRadius) * fraction;
    
    return Rect.fromCircle(center: center, radius: radius);
  }

  @override
  bool shouldReclip(CircleRevealClipper oldClipper) {
    return oldClipper.fraction != fraction;
  }
}

/// PageTransitions class - now only contains circle morph for performance
class PageTransitions {
  // All transition methods now use circle morph for consistency and performance
  static PageRouteBuilder circleMorph(Widget page) => CircleMorphRoute(page: page);
  
  // Legacy methods redirected to circle morph
  static PageRouteBuilder slideRight(Widget page) => CircleMorphRoute(page: page);
  static PageRouteBuilder slideLeft(Widget page) => CircleMorphRoute(page: page);
  static PageRouteBuilder slideUp(Widget page) => CircleMorphRoute(page: page);
  static PageRouteBuilder slideDown(Widget page) => CircleMorphRoute(page: page);
  static PageRouteBuilder fade(Widget page) => CircleMorphRoute(page: page);
  static PageRouteBuilder scale(Widget page) => CircleMorphRoute(page: page);
  static PageRouteBuilder rotate(Widget page) => CircleMorphRoute(page: page);
  static PageRouteBuilder flip(Widget page) => CircleMorphRoute(page: page);
  static PageRouteBuilder liquidMorph(Widget page) => CircleMorphRoute(page: page);
  static PageRouteBuilder particleDissolve(Widget page) => CircleMorphRoute(page: page);
  static PageRouteBuilder glitch(Widget page) => CircleMorphRoute(page: page);
  static PageRouteBuilder morphSlideRight(Widget page) => CircleMorphRoute(page: page);
  static PageRouteBuilder morphSlideLeft(Widget page) => CircleMorphRoute(page: page);
}
