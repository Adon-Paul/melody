
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../auth/login_page.dart'; // Import your login page
import 'slide_transition.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
            Navigator.pushReplacement(
              context,
              SlideRightRoute(page: const LoginPage()),
            );
          }
        },
        child: Stack(
          children: [
            // Animated gradient background
            const _AnimatedBackground(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Glowing logo
                  _GlowingLogo(),
                  const SizedBox(height: 16),
                  // App name
                  const Text(
                    'Melody',
                    style: TextStyle(
                      fontFamily: 'serif',
                      color: Colors.white,
                      fontSize: 48.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(blurRadius: 16, color: Colors.greenAccent, offset: Offset(0, 0)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    'Feel the music. Live the moment.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 120),
                  // Button with glass effect
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50.0),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: FloatingActionButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            SlideRightRoute(page: const LoginPage()),
                          );
                        },
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Swipe up hint
                  Column(
                    children: const [
                      Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white70, size: 36),
                      Text(
                        'Swipe up to unlock',
                        style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// Animated gradient background
class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();
  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade900,
                Colors.greenAccent.withOpacity(0.7),
                Colors.black,
                Colors.blueGrey.shade900.withOpacity(0.7),
              ],
              stops: [
                0.0,
                0.5 + 0.2 * math.sin(_controller.value * 2 * math.pi),
                0.8,
                1.0,
              ],
            ),
          ),
        );
      },
    );
  }
}

// Glowing logo widget
class _GlowingLogo extends StatefulWidget {
  @override
  State<_GlowingLogo> createState() => _GlowingLogoState();
}

class _GlowingLogoState extends State<_GlowingLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double glow = 16 + 16 * _controller.value;
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.greenAccent.withOpacity(0.7),
                blurRadius: glow,
                spreadRadius: 2,
              ),
            ],
            gradient: const RadialGradient(
              colors: [Colors.greenAccent, Colors.green, Colors.black],
              stops: [0.2, 0.7, 1.0],
            ),
          ),
          child: const Icon(Icons.music_note, color: Colors.white, size: 40),
        );
      },
    );
  }
}
