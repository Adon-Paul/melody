import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/modern_button.dart';
import '../core/widgets/modern_text_field.dart';
import '../core/widgets/modern_toast.dart';
import '../core/widgets/animated_background.dart';

class ComponentTestScreen extends StatefulWidget {
  const ComponentTestScreen({super.key});

  @override
  State<ComponentTestScreen> createState() => _ComponentTestScreenState();
}

class _ComponentTestScreenState extends State<ComponentTestScreen> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modern Components Test'),
        backgroundColor: AppTheme.surfaceColor,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Card
                  Card(
                    elevation: 10,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.science,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Component Testing Lab',
                            style: AppTheme.headlineMedium.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Testing all modern UI components',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Text Field Test
                  ModernTextField(
                    controller: _textController,
                    label: 'Test Input',
                    hintText: 'Enter some text to test',
                    prefixIcon: Icons.edit,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter some text';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field Test
                  ModernTextField(
                    label: 'Password Test',
                    hintText: 'Enter password',
                    isPassword: true,
                    prefixIcon: Icons.lock,
                  ),
                  const SizedBox(height: 24),

                  // Button Tests
                  ModernButton(
                    text: 'Primary Button',
                    onPressed: () {
                      ModernToast.show(
                        context,
                        'Primary button pressed!',
                        type: ToastType.success,
                      );
                    },
                    width: double.infinity,
                  ),
                  const SizedBox(height: 16),

                  ModernButton(
                    text: 'Outlined Button',
                    variant: ButtonVariant.outlined,
                    iconData: Icons.star,
                    onPressed: () {
                      ModernToast.show(
                        context,
                        'Outlined button pressed!',
                        type: ToastType.info,
                      );
                    },
                    width: double.infinity,
                  ),
                  const SizedBox(height: 16),

                  ModernButton(
                    text: 'Loading Button',
                    isLoading: true,
                    onPressed: null,
                    width: double.infinity,
                  ),
                  const SizedBox(height: 24),

                  // Toast Tests
                  Row(
                    children: [
                      Expanded(
                        child: ModernButton(
                          text: 'Success',
                          onPressed: () {
                            ModernToast.show(
                              context,
                              'Success message!',
                              type: ToastType.success,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ModernButton(
                          text: 'Error',
                          onPressed: () {
                            ModernToast.show(
                              context,
                              'Error message!',
                              type: ToastType.error,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ModernButton(
                          text: 'Warning',
                          onPressed: () {
                            ModernToast.show(
                              context,
                              'Warning message!',
                              type: ToastType.warning,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ModernButton(
                          text: 'Info',
                          onPressed: () {
                            ModernToast.show(
                              context,
                              'Info message!',
                              type: ToastType.info,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.primaryColor,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All Components Ready!',
                          style: AppTheme.titleMedium.copyWith(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Modern UI system is working perfectly',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
