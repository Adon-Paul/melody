import 'package:flutter/material.dart';
import '../transitions/page_transitions.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/modern_button.dart';

class TransitionDemoPage extends StatelessWidget {
  const TransitionDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: AnimatedBackground(
        showParticles: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.textSecondary.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.animation,
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Transition Showcase',
                        style: AppTheme.headlineLarge.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Experience MELODY\'s creative page transitions',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Transition Buttons Grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                    children: [
                      _TransitionButton(
                        title: 'Slide Right',
                        subtitle: 'Enhanced slide',
                        icon: Icons.arrow_forward,
                        gradientColors: const [Color(0xFF6A5ACD), Color(0xFF9370DB)],
                        onTap: () => Navigator.push(
                          context,
                          PageTransitions.slideRight(const DemoTargetPage(title: 'Slide Right')),
                        ),
                      ),
                      _TransitionButton(
                        title: 'Slide Left',
                        subtitle: 'Smooth return',
                        icon: Icons.arrow_back,
                        gradientColors: const [Color(0xFF20B2AA), Color(0xFF48CAE4)],
                        onTap: () => Navigator.push(
                          context,
                          PageTransitions.slideLeft(const DemoTargetPage(title: 'Slide Left')),
                        ),
                      ),
                      _TransitionButton(
                        title: 'Slide Up',
                        subtitle: 'Elastic bounce',
                        icon: Icons.arrow_upward,
                        gradientColors: const [Color(0xFF32CD32), Color(0xFF7FFF00)],
                        onTap: () => Navigator.push(
                          context,
                          PageTransitions.slideUp(const DemoTargetPage(title: 'Elastic Slide Up')),
                        ),
                      ),
                      _TransitionButton(
                        title: '3D Flip',
                        subtitle: 'Horizontal flip',
                        icon: Icons.flip,
                        gradientColors: const [Color(0xFFFF6347), Color(0xFFFF7F7F)],
                        onTap: () => Navigator.push(
                          context,
                          PageTransitions.flip(const DemoTargetPage(title: '3D Flip')),
                        ),
                      ),
                      _TransitionButton(
                        title: 'Circle Morph',
                        subtitle: 'Expanding circle',
                        icon: Icons.circle_outlined,
                        gradientColors: const [Color(0xFFFFD700), Color(0xFFFFA500)],
                        onTap: () => Navigator.push(
                          context,
                          PageTransitions.circleMorph(const DemoTargetPage(title: 'Circle Morph')),
                        ),
                      ),
                      _TransitionButton(
                        title: 'Liquid Morph',
                        subtitle: 'Flowing wave',
                        icon: Icons.water_drop,
                        gradientColors: const [Color(0xFF1E90FF), Color(0xFF87CEEB)],
                        onTap: () => Navigator.push(
                          context,
                          PageTransitions.liquidMorph(const DemoTargetPage(title: 'Liquid Morph')),
                        ),
                      ),
                      _TransitionButton(
                        title: 'Particle Dissolve',
                        subtitle: 'Floating particles',
                        icon: Icons.scatter_plot,
                        gradientColors: const [Color(0xFF9932CC), Color(0xFFBA55D3)],
                        onTap: () => Navigator.push(
                          context,
                          PageTransitions.particleDissolve(const DemoTargetPage(title: 'Particle Dissolve')),
                        ),
                      ),
                      _TransitionButton(
                        title: 'Glitch Effect',
                        subtitle: 'Digital glitch',
                        icon: Icons.electrical_services,
                        gradientColors: const [Color(0xFFDC143C), Color(0xFFFF1493)],
                        onTap: () => Navigator.push(
                          context,
                          PageTransitions.glitch(const DemoTargetPage(title: 'Glitch Effect')),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Back Button
                ModernButton(
                  text: 'Back to App',
                  onPressed: () => Navigator.pop(context),
                  variant: ButtonVariant.outlined,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransitionButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _TransitionButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 32,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DemoTargetPage extends StatelessWidget {
  final String title;
  
  const DemoTargetPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: AnimatedBackground(
        showParticles: true,
        showGradient: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.textSecondary.withOpacity(0.2)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        title,
                        style: AppTheme.headlineLarge.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Transition completed successfully!',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ModernButton(
                        text: 'Go Back',
                        onPressed: () => Navigator.pop(context),
                        variant: ButtonVariant.filled,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
