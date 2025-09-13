import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/modern_button.dart';
import '../../core/widgets/modern_text_field.dart';
import '../../core/widgets/modern_toast.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/services/auth_service.dart';
import '../../core/transitions/page_transitions.dart';
import 'login_screen.dart';
import '../home/home_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final credential = await authService.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (credential != null && mounted) {
        // Navigate to home screen
        Navigator.pushReplacement(
          context,
          PageTransitions.circleMorph(const HomeScreen()),
        );
      } else if (mounted) {
        ModernToast.show(
          context,
          'Sign up failed. Please try again.',
          type: ToastType.error,
        );
      }
    } catch (e) {
      if (mounted) {
        ModernToast.show(
          context,
          'An error occurred: ${e.toString()}',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // Allow back to login screen
      onPopInvokedWithResult: (didPop, result) {
        // Handle any cleanup when navigating back to login
        if (didPop) {
          // Clear any form state if needed
        }
      },
      child: Scaffold(
        body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 20,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: AppTheme.surfaceColor,  // Dark surface instead of white
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // App Logo/Icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person_add,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Welcome Text
                          Text(
                            'Create Account',
                            style: AppTheme.headlineMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Join us and start your musical journey',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),

                          // Name Field
                          ModernTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            keyboardType: TextInputType.name,
                            prefixIcon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              if (value.length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          ModernTextField(
                            controller: _emailController,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          ModernTextField(
                            controller: _passwordController,
                            label: 'Password',
                            obscureText: _obscurePassword,
                            prefixIcon: Icons.lock_outline,
                            suffixIconWidget: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirm Password Field
                          ModernTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            obscureText: _obscureConfirmPassword,
                            prefixIcon: Icons.lock_outline,
                            suffixIconWidget: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please confirm your password';
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Sign Up Button
                          ModernButton(
                            text: 'Create Account',
                            onPressed: _isLoading ? null : _handleSignUp,
                            isLoading: _isLoading,
                            width: double.infinity,
                          ),
                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'or',
                                  style: AppTheme.bodySmall.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: AppTheme.textSecondary.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Google Sign Up Button
                          GestureDetector(
                            onTap: () async {
                              final authService = context.read<AuthService>();
                              final navigator = Navigator.of(context);
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              
                              try {
                                final credential = await authService.signInWithGoogle();
                                
                                if (credential != null) {
                                  if (mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Welcome! Account created successfully.'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    navigator.pushReplacement(
                                      PageTransitions.circleMorph(const HomeScreen()),
                                    );
                                  }
                                } else {
                                  // Error message will be handled by AuthService
                                  final errorMessage = authService.errorMessage;
                                  if (errorMessage != null && mounted) {
                                    scaffoldMessenger.showSnackBar(
                                      SnackBar(
                                        content: Text(errorMessage),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Google sign-up failed: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.g_mobiledata,
                                          color: Colors.black87,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Continue with Google',
                                        style: AppTheme.titleMedium.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Continue as Guest Button
                          ModernButton(
                            text: 'Continue as Guest',
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                PageTransitions.circleMorph(const HomeScreen()),
                              );
                            },
                            variant: ButtonVariant.text,
                            iconData: Icons.person_outline,
                            width: double.infinity,
                          ),
                          const SizedBox(height: 24),

                          // Sign In Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account? ",
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    PageTransitions.circleMorph(const LoginScreen()),
                                  );
                                },
                                child: Text(
                                  'Sign In',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
