import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_background.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.music_note,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Welcome to MELODY',
                    style: AppTheme.displayMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,  // Use theme color instead of white
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your musical journey begins here',
                    style: AppTheme.bodyLarge.copyWith(
                      color: AppTheme.textSecondary,  // Use theme color
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,  // Dark surface
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Home screen is coming soon!\nStay tuned for amazing features.',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textPrimary,  // Use theme color
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
