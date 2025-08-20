import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/modern_button.dart';
import 'core/widgets/modern_text_field.dart';
import 'core/widgets/animated_background.dart';
import 'core/widgets/modern_toast.dart';

class TestModernComponents extends StatefulWidget {
  const TestModernComponents({super.key});

  @override
  State<TestModernComponents> createState() => _TestModernComponentsState();
}

class _TestModernComponentsState extends State<TestModernComponents> {
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Modern Components Test', style: AppTheme.titleLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AnimatedBackground(
        showParticles: true,
        showGradient: true,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Modern Text Field
              ModernTextField(
                controller: _textController,
                labelText: 'Test Input',
                hintText: 'Enter some text...',
                prefixIcon: Icons.search,
              ),
              
              const SizedBox(height: 24),
              
              // Modern Button
              ModernButton(
                text: 'Primary Button',
                onPressed: () {
                  ModernToast.showSuccess(
                    context,
                    message: 'Button pressed successfully!',
                    title: 'Success',
                  );
                },
                icon: const Icon(Icons.check, color: Colors.white),
              ),
              
              const SizedBox(height: 16),
              
              // Outlined Button
              ModernButton(
                text: 'Outlined Button',
                onPressed: () {
                  ModernToast.showInfo(
                    context,
                    message: 'This is an info message',
                  );
                },
                isOutlined: true,
              ),
              
              const SizedBox(height: 16),
              
              // Glass Button
              GlassButton(
                text: 'Glass Button',
                onPressed: () {
                  ModernToast.showWarning(
                    context,
                    message: 'This is a warning message',
                    title: 'Warning',
                  );
                },
                icon: const Icon(Icons.warning, color: Colors.white),
              ),
              
              const SizedBox(height: 32),
              
              // Error Button
              ModernButton(
                text: 'Error Toast',
                onPressed: () {
                  ModernToast.showError(
                    context,
                    message: 'Something went wrong!',
                    title: 'Error',
                  );
                },
                backgroundColor: AppTheme.errorColor,
              ),
              
              const Spacer(),
              
              // Glowing Orb
              const Center(
                child: GlowingOrb(
                  size: 80,
                  color: AppTheme.primaryColor,
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
