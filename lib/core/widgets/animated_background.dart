import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class AnimatedBackground extends StatefulWidget {
  final Widget? child;
  final bool showParticles;
  final bool showGradient;
  
  const AnimatedBackground({
    super.key,
    this.child,
    this.showParticles = true,
    this.showGradient = true,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  late AnimationController _gradientController;
  late AnimationController _particleController;
  late Animation<double> _gradientAnimation;
  
  final List<Particle> _particles = [];
  final int _particleCount = 50;

  @override
  void initState() {
    super.initState();
    
    _gradientController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _gradientAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_gradientController);
    
    if (widget.showParticles) {
      _initializeParticles();
    }
  }

  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        Particle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          size: random.nextDouble() * 3 + 1,
          speed: random.nextDouble() * 0.02 + 0.01,
          opacity: random.nextDouble() * 0.5 + 0.1,
        ),
      );
    }
  }

  @override
  void dispose() {
    _gradientController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient Background
        if (widget.showGradient)
          AnimatedBuilder(
            animation: _gradientAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.backgroundColor,
                      AppTheme.primaryColor.withOpacity(0.1),
                      AppTheme.accentColor.withOpacity(0.05),
                      AppTheme.backgroundColor,
                    ],
                    stops: [
                      0.0,
                      0.3 + 0.2 * math.sin(_gradientAnimation.value * 2 * math.pi),
                      0.7 + 0.2 * math.cos(_gradientAnimation.value * 2 * math.pi),
                      1.0,
                    ],
                  ),
                ),
              );
            },
          ),
        
        // Floating Particles
        if (widget.showParticles)
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: ParticlePainter(_particles, _particleController.value),
                size: Size.infinite,
              );
            },
          ),
        
        // Content
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });

  void update() {
    y -= speed;
    if (y < 0) {
      y = 1.0;
      x = math.Random().nextDouble();
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.screen;

    for (final particle in particles) {
      particle.update();
      
      final x = particle.x * size.width;
      final y = particle.y * size.height;
      
      paint.color = AppTheme.primaryColor.withOpacity(particle.opacity);
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
      
      // Add subtle glow effect
      paint.color = AppTheme.primaryColor.withOpacity(particle.opacity * 0.3);
      canvas.drawCircle(
        Offset(x, y),
        particle.size * 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class GlowingOrb extends StatefulWidget {
  final double size;
  final Color color;
  final Duration duration;
  
  const GlowingOrb({
    super.key,
    this.size = 100,
    this.color = AppTheme.primaryColor,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<GlowingOrb> createState() => _GlowingOrbState();
}

class _GlowingOrbState extends State<GlowingOrb>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_glowAnimation.value * 0.6),
                blurRadius: 20 * _glowAnimation.value,
                spreadRadius: 5 * _glowAnimation.value,
              ),
            ],
            gradient: RadialGradient(
              colors: [
                widget.color.withOpacity(_glowAnimation.value),
                widget.color.withOpacity(_glowAnimation.value * 0.3),
                Colors.transparent,
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
          child: const Icon(
            Icons.music_note,
            color: Colors.white,
            size: 40,
          ),
        );
      },
    );
  }
}

class WaveBackground extends StatefulWidget {
  final Widget? child;
  
  const WaveBackground({super.key, this.child});

  @override
  State<WaveBackground> createState() => _WaveBackgroundState();
}

class _WaveBackgroundState extends State<WaveBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: AppTheme.backgroundColor),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: WavePainter(_controller.value),
              size: Size.infinite,
            );
          },
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final double animationValue;

  WavePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppTheme.primaryColor.withOpacity(0.1);

    final path = Path();
    final waveHeight = 30.0;
    final waveLength = size.width / 2;
    
    path.moveTo(0, size.height * 0.8);
    
    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height * 0.8 + 
          waveHeight * math.sin((x / waveLength + animationValue) * 2 * math.pi);
      path.lineTo(x, y);
    }
    
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // Second wave
    paint.color = AppTheme.accentColor.withOpacity(0.05);
    final path2 = Path();
    path2.moveTo(0, size.height * 0.9);
    
    for (double x = 0; x <= size.width; x += 1) {
      final y = size.height * 0.9 + 
          waveHeight * 0.5 * math.cos((x / waveLength - animationValue) * 2 * math.pi);
      path2.lineTo(x, y);
    }
    
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
