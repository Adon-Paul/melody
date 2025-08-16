import 'package:flutter/material.dart';
import 'dart:math' as math;
// Animated gradient background
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});
  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground> with SingleTickerProviderStateMixin {
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
class GlowingLogo extends StatefulWidget {
  const GlowingLogo({super.key});
  @override
  State<GlowingLogo> createState() => _GlowingLogoState();
}

class _GlowingLogoState extends State<GlowingLogo> with SingleTickerProviderStateMixin {
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
