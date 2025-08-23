import 'package:flutter/material.dart';
import 'dart:math' as math;

class AdvancedTransitions {
  // 3D Flip transition
  static PageRouteBuilder<T> flip3D<T>(Widget page, {
    Duration duration = const Duration(milliseconds: 600),
    bool flipHorizontal = true,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final rotationValue = animation.value * math.pi; // π radians = 180°
            
            if (animation.value <= 0.5) {
              // First half - hide current page
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateY(flipHorizontal ? rotationValue : 0)
                  ..rotateX(flipHorizontal ? 0 : rotationValue),
                child: Opacity(
                  opacity: 1.0 - animation.value * 2,
                  child: Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                ),
              );
            } else {
              // Second half - show new page
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // perspective
                  ..rotateY(flipHorizontal ? (rotationValue - math.pi) : 0)
                  ..rotateX(flipHorizontal ? 0 : (rotationValue - math.pi)),
                child: Opacity(
                  opacity: (animation.value - 0.5) * 2,
                  child: child,
                ),
              );
            }
          },
        );
      },
    );
  }

  // Morph transition with hero-like effect
  static PageRouteBuilder<T> morph<T>(Widget page, {
    Duration duration = const Duration(milliseconds: 800),
    Offset? startPosition,
    Size? startSize,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;
        
        var scaleTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve));

        var positionTween = Tween<Offset>(
          begin: startPosition ?? const Offset(0.5, 0.5),
          end: Offset.zero,
        ).chain(CurveTween(curve: curve));

        var borderRadiusTween = Tween<double>(
          begin: 50.0,
          end: 0.0,
        ).chain(CurveTween(curve: curve));

        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final scale = scaleTween.evaluate(animation);
            final position = positionTween.evaluate(animation);
            final borderRadius = borderRadiusTween.evaluate(animation);

            return Transform.scale(
              scale: scale,
              child: Transform.translate(
                offset: Offset(
                  position.dx * MediaQuery.of(context).size.width,
                  position.dy * MediaQuery.of(context).size.height,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: child,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Liquid morph transition
  static PageRouteBuilder<T> liquidMorph<T>(Widget page, {
    Duration duration = const Duration(milliseconds: 1000),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            return ClipPath(
              clipper: LiquidClipper(animation.value),
              child: child,
            );
          },
        );
      },
    );
  }

  // Cube transition
  static PageRouteBuilder<T> cube<T>(Widget page, {
    Duration duration = const Duration(milliseconds: 700),
    bool rotateLeft = true,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final rotationAngle = (rotateLeft ? -1 : 1) * animation.value * math.pi / 2;
        
        return Transform(
          alignment: rotateLeft ? Alignment.centerRight : Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(rotationAngle),
          child: child,
        );
      },
    );
  }

  // Fold transition
  static PageRouteBuilder<T> fold<T>(Widget page, {
    Duration duration = const Duration(milliseconds: 800),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final foldValue = animation.value;
            
            return Transform(
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(-foldValue * math.pi / 4),
              child: Transform.scale(
                scale: 1.0 - foldValue * 0.3,
                child: Opacity(
                  opacity: 1.0 - foldValue * 0.5,
                  child: child,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Scale and rotate combined
  static PageRouteBuilder<T> scaleRotate<T>(Widget page, {
    Duration duration = const Duration(milliseconds: 600),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.elasticOut;
        
        final scaleTween = Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: curve));
        final rotateTween = Tween<double>(begin: -0.5, end: 0.0)
            .chain(CurveTween(curve: curve));
        
        return Transform.scale(
          scale: scaleTween.evaluate(animation),
          child: Transform.rotate(
            angle: rotateTween.evaluate(animation) * math.pi,
            child: child,
          ),
        );
      },
    );
  }

  // Circle morph transition
  static PageRouteBuilder<T> circleMorph<T>(Widget page, {
    Duration duration = const Duration(milliseconds: 800),
    Offset? centerOffset,
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeInOutCubic;
        
        final scaleTween = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: curve));

        return AnimatedBuilder(
          animation: animation,
          child: child,
          builder: (context, child) {
            final scale = scaleTween.evaluate(animation);
            final screenSize = MediaQuery.of(context).size;
            final center = centerOffset ?? 
                Offset(screenSize.width / 2, screenSize.height / 2);
            
            // Calculate the maximum radius needed to cover the screen
            final maxRadius = math.sqrt(
              math.pow(screenSize.width, 2) + math.pow(screenSize.height, 2)
            ) / 2;

            return ClipPath(
              clipper: CircleRevealClipper(
                center: center,
                radius: scale * maxRadius,
              ),
              child: child,
            );
          },
        );
      },
    );
  }
}

// Custom clipper for circle reveal effect
class CircleRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  CircleRevealClipper({
    required this.center,
    required this.radius,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return path;
  }

  @override
  bool shouldReclip(CircleRevealClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}

// Custom clipper for liquid morph effect
class LiquidClipper extends CustomClipper<Path> {
  final double progress;

  LiquidClipper(this.progress);

  @override
  Path getClip(Size size) {
    var path = Path();
    
    if (progress <= 0) {
      return path;
    }

    final width = size.width;
    final height = size.height;
    
    // Create liquid-like morphing effect
    final waveHeight = height * 0.1 * (1 - progress);
    final centerY = height * progress;
    
    path.moveTo(0, centerY + waveHeight);
    
    // Create wave-like curves
    for (double x = 0; x <= width; x += width / 10) {
      final waveY = centerY + waveHeight * 
          (0.5 + 0.5 * math.sin(x / width * 2 * math.pi));
      path.lineTo(x, waveY);
    }
    
    path.lineTo(width, height);
    path.lineTo(0, height);
    path.close();
    
    return path;
  }

  @override
  bool shouldReclip(LiquidClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}

// Extension for easy navigation
extension NavigationExtensions on BuildContext {
  Future<T?> pushFlip3D<T>(Widget page) {
    return Navigator.push<T>(this, AdvancedTransitions.flip3D<T>(page));
  }

  Future<T?> pushMorph<T>(Widget page) {
    return Navigator.push<T>(this, AdvancedTransitions.morph<T>(page));
  }

  Future<T?> pushLiquidMorph<T>(Widget page) {
    return Navigator.push<T>(this, AdvancedTransitions.liquidMorph<T>(page));
  }

  Future<T?> pushCube<T>(Widget page) {
    return Navigator.push<T>(this, AdvancedTransitions.cube<T>(page));
  }

  Future<T?> pushFold<T>(Widget page) {
    return Navigator.push<T>(this, AdvancedTransitions.fold<T>(page));
  }

  Future<T?> pushScaleRotate<T>(Widget page) {
    return Navigator.push<T>(this, AdvancedTransitions.scaleRotate<T>(page));
  }

  Future<T?> pushCircleMorph<T>(Widget page) {
    return Navigator.push<T>(this, AdvancedTransitions.circleMorph<T>(page));
  }
}
