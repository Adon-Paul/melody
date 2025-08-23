import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/animated_background.dart';
import '../../core/widgets/modern_button.dart';
import '../../core/widgets/modern_text_field.dart';
import '../../core/widgets/modern_toast.dart';
import '../../core/widgets/password_reset_dialog.dart';
import '../../core/services/auth_service.dart';
import '../../core/transitions/page_transitions.dart';
import '../home/home_screen.dart';
import 'signup_screen.dart';

class ModernLoginScreen extends StatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  State<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends State<ModernLoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _containerController;
  late AnimationController _buttonController;

  @override
  void initState() {
    super.initState();
    _containerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _containerController.forward();
    
    await Future.delayed(const Duration(milliseconds: 200));
    _buttonController.forward();
  }

  @override
  void dispose() {
    _containerController.dispose();
    _buttonController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = context.read<AuthService>();
    
    final result = await authService.signInWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (mounted) {
      if (result != null) {
        ModernToast.showSuccess(
          context,
          message: 'Welcome back!',
          title: 'Login Successful',
        );
        
        Navigator.pushReplacement(
          context,
          PageTransitions.circleMorph(const HomeScreen()),
        );
      } else if (authService.errorMessage != null) {
        ModernToast.showError(
          context,
          message: authService.errorMessage!,
          title: 'Login Failed',
        );
      }
    }
  }

  void _handleGoogleSignIn() async {
    final authService = context.read<AuthService>();
    
    final result = await authService.signInWithGoogle();
    
    if (mounted) {
      if (result != null) {
        ModernToast.showSuccess(
          context,
          message: 'Welcome!',
          title: 'Google Sign-In Successful',
        );
        
        Navigator.pushReplacement(
          context,
          PageTransitions.liquidMorph(const HomeScreen()),
        );
      } else if (authService.errorMessage != null) {
        ModernToast.showInfo(
          context,
          message: authService.errorMessage!,
        );
      }
    }
  }

  void _continueAsGuest() {
    ModernToast.showInfo(
      context,
      message: 'Continuing as guest',
    );
    
    Navigator.pushReplacement(
      context,
      PageTransitions.glitch(const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: AnimatedBackground(
        showParticles: true,
        showGradient: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Logo
                    GlowingOrb(
                      size: 100,
                      color: AppTheme.primaryColor,
                    ).animate().scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.elasticOut,
                      duration: 800.ms,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Welcome Text
                    Column(
                      children: [
                        Text(
                          'Welcome Back',
                          style: AppTheme.displayMedium.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ).animate().fadeIn().slideY(begin: -0.3),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          'Sign in to continue your musical journey',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ).animate(delay: 200.ms).fadeIn().slideY(begin: -0.3),
                      ],
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Login Form
                    AnimatedBuilder(
                      animation: _containerController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _containerController.value)),
                          child: Opacity(
                            opacity: _containerController.value,
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppTheme.glassBackground,
                                borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                border: Border.all(
                                  color: AppTheme.glassBorder,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Email Field
                                  ModernTextField(
                                    controller: _emailController,
                                    labelText: 'Email',
                                    hintText: 'Enter your email',
                                    prefixIcon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your email';
                                      }
                                      if (!value.contains('@')) {
                                        return 'Please enter a valid email';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Password Field
                                  ModernTextField(
                                    controller: _passwordController,
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: Icons.lock_outline,
                                    isPassword: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter your password';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Forgot Password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => const PasswordResetDialog(),
                                        );
                                      },
                                      child: Text(
                                        'Forgot Password?',
                                        style: AppTheme.bodyMedium.copyWith(
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Login Button
                    AnimatedBuilder(
                      animation: _buttonController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, 20 * (1 - _buttonController.value)),
                          child: Opacity(
                            opacity: _buttonController.value,
                            child: Consumer<AuthService>(
                              builder: (context, authService, child) {
                                return SizedBox(
                                  width: double.infinity,
                                  child: ModernButton(
                                    text: 'Sign In',
                                    onPressed: authService.isLoading ? null : _handleLogin,
                                    isLoading: authService.isLoading,
                                    icon: const Icon(Icons.login, color: Colors.white),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Divider
                    Text(
                      '─── or continue with ───',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ).animate(delay: 600.ms).fadeIn(),
                    
                    const SizedBox(height: 24),
                    
                    // Social Login Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ModernButton(
                          text: 'Google',
                          onPressed: _handleGoogleSignIn,
                          isOutlined: true,
                          icon: const Icon(Icons.g_mobiledata, size: 28),
                        ).animate(delay: 800.ms).fadeIn().scale(begin: const Offset(0.8, 0.8)),
                        
                        const SizedBox(width: 16),
                        
                        GlassButton(
                          text: 'Guest',
                          onPressed: _continueAsGuest,
                          icon: const Icon(Icons.person_outline, color: Colors.white),
                        ).animate(delay: 1000.ms).fadeIn().scale(begin: const Offset(0.8, 0.8)),
                      ],
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Sign Up Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account? ",
                          style: AppTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              PageTransitions.flip(const SignUpScreen()),
                            );
                          },
                          child: Text(
                            'Sign Up',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ).animate(delay: 1200.ms).fadeIn(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
