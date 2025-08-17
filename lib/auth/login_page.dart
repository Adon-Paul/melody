import '../ui elements/glass_toast.dart';
// Import necessary packages for UI, Firebase, Google Sign-In, and toasts.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';


// Import local project files. Ensure these paths are correct in your project structure.
import 'signup_page.dart';

import '../test_page.dart';
import '../ui elements/slide_transition.dart';
import '../ui elements/social_sign_in_button.dart';
import 'dart:ui';
import '../ui elements/pretty_background.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Text editing controllers for the email and password fields.
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // State variables to manage loading indicators and display error messages.
  bool _isLoading = false;

  // --- Authentication Methods ---

  /// Handles the sign-in process with email and password.
  Future<void> _login() async {
    // Check if the widget is still in the widget tree before updating state.
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Attempt to sign in with the provided credentials.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // On success, show a confirmation toast and navigate to the dashboard page.
      if (mounted) {
        GlassToast.show(
          context,
          message: 'Login Successful!',
          backgroundColor: const Color(0xCC1B5E20),
          icon: Icons.check_circle_outline,
        );
        // Using pushReplacement prevents the user from navigating back to the login page.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TestPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Show user-friendly error messages for common auth errors
      String errorMsg;
      switch (e.code) {
        case 'user-not-found':
          errorMsg = 'No account found for that email.';
          break;
        case 'wrong-password':
          errorMsg = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          errorMsg = 'Please enter a valid email address.';
          break;
        case 'user-disabled':
          errorMsg = 'This account has been disabled. Contact support.';
          break;
        case 'too-many-requests':
          errorMsg = 'Too many attempts. Please wait and try again.';
          break;
        case 'network-request-failed':
          errorMsg = 'Network error. Please check your connection.';
          break;
        default:
          errorMsg = 'Could not sign in. Please check your credentials.';
      }
      if (mounted) {
        GlassToast.show(
          context,
          message: errorMsg,
          backgroundColor: Colors.red.withOpacity(0.85),
          icon: Icons.error_outline,
        );
      }
    } catch (e) {
      // Handle any other unexpected errors.
      if (mounted) {
        GlassToast.show(
          context,
          message: 'An unexpected error occurred. Please try again.',
          backgroundColor: Colors.red.withOpacity(0.85),
          icon: Icons.error_outline,
        );
      }
    } finally {
      // Ensure the loading indicator is turned off, regardless of success or failure.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Handles the sign-in process with a Google account.
  Future<void> _signInWithGoogle() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();
      final GoogleSignInAuthentication? googleSignInAuthentication =
          await googleSignInAccount?.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication?.idToken,
          accessToken: googleSignInAuthentication?.accessToken);
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        GlassToast.show(
          context,
          message: 'Google Sign-In Successful!',
          backgroundColor: const Color(0xCC1B5E20),
          icon: Icons.check_circle_outline,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TestPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMsg = 'An account already exists with a different sign-in method.';
          break;
        case 'invalid-credential':
          errorMsg = 'Invalid Google credentials. Please try again.';
          break;
        case 'user-disabled':
          errorMsg = 'This account has been disabled. Contact support.';
          break;
        case 'user-not-found':
          errorMsg = 'No account found for this Google account.';
          break;
        case 'network-request-failed':
          errorMsg = 'Network error. Please check your connection.';
          break;
        default:
          errorMsg = 'Google sign-in failed. Please try again.';
      }
      if (mounted) {
        GlassToast.show(
          context,
          message: errorMsg,
          backgroundColor: Colors.red.withOpacity(0.85),
          icon: Icons.error_outline,
        );
      }
    } catch (e) {
      if (mounted) {
        GlassToast.show(
          context,
          message: 'Google sign-in failed. Please try again.',
          backgroundColor: Colors.red.withOpacity(0.85),
          icon: Icons.error_outline,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // --- Widget Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            const AnimatedBackground(),
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const GlowingLogo(),
                            const SizedBox(height: 28), // moved music symbol a bit down
                            const Text(
                              'Welcome Back',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(blurRadius: 12, color: Colors.greenAccent, offset: Offset(0, 0)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Your music awaits.',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 32),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24.0),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                                child: Container(
                                  padding: const EdgeInsets.all(32.0),
                                  margin: const EdgeInsets.symmetric(horizontal: 24.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        spreadRadius: 5,
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // ...existing code for form fields, buttons, etc...
                                        // Email Text Field
                                        TextField(
                                          controller: _emailController,
                                          keyboardType: TextInputType.emailAddress,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(Icons.person_outline, color: Colors.white54),
                                            hintText: 'Email',
                                            hintStyle: const TextStyle(color: Colors.white54),
                                            filled: true,
                                            fillColor: Colors.grey[700],
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Password Text Field
                                        TextField(
                                          controller: _passwordController,
                                          obscureText: true,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: InputDecoration(
                                            prefixIcon: const Icon(Icons.lock_outline, color: Colors.white54),
                                            hintText: 'Password',
                                            hintStyle: const TextStyle(color: Colors.white54),
                                            filled: true,
                                            fillColor: Colors.grey[700],
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        // Login Button
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(16),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: const Color(0xAA90EE90), // much lighter green glass effect
                                                borderRadius: BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.18),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: ElevatedButton(
                                                onPressed: _isLoading ? null : _login,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.transparent,
                                                  shadowColor: Colors.transparent,
                                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(16),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: _isLoading
                                                    ? const SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child: CircularProgressIndicator(
                                                          color: Colors.white,
                                                          strokeWidth: 2,
                                                        ),
                                                      )
                                                    : const Text(
                                                        'Log In',
                                                        style: TextStyle(fontSize: 18, color: Colors.white),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Error message removed: now only shown as toast notification
                                        const SizedBox(height: 24),
                                        const Text(
                                          '-----  or sign in with  -----',
                                          style: TextStyle(color: Colors.white70),
                                        ),
                                        const SizedBox(height: 24),
                                        // Social Sign-In Buttons
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            SocialSignInButton(
                                              imagePath: 'lib/images/google_logo.png',
                                              onTap: _isLoading ? () {} : _signInWithGoogle,
                                            ),
                                            const SizedBox(width: 24),
                                            SocialSignInButton(
                                              imagePath: 'lib/images/facebook_logo.png',
                                              onTap: () {
                                                GlassToast.show(
                                                  context,
                                                  message: 'Facebook Sign-In is not implemented yet.',
                                                  backgroundColor: const Color(0xCC1B5E20),
                                                  icon: Icons.info_outline,
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        // Sign Up Navigation (fix overflow)
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            const Text(
                                              "Don't have an account? ",
                                              style: TextStyle(color: Colors.white70),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  SlideRightRoute(page: const SignupPage()),
                                                );
                                              },
                                              child: const Text(
                                                'Sign Up',
                                                style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Forgot Password
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(30),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                            child: Container(
                                              margin: const EdgeInsets.only(top: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[700]!.withOpacity(0.45),
                                                borderRadius: BorderRadius.circular(30),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.15),
                                                    blurRadius: 8,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    SlideRightRoute(page: const ForgotPasswordPage()),
                                                  );
                                                },
                                                child: const Text(
                                                  'Forgot password?',
                                                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        // Continue as Guest Button
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(30),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                            child: Container(
                                              margin: const EdgeInsets.only(top: 8),
                                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.45),
                                                borderRadius: BorderRadius.circular(30),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.18),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.pushReplacement(
                                                    context,
                                                    SlideRightRoute(page: const TestPage()),
                                                  );
                                                },
                                                child: const Text(
                                                  'Continue as Guest',
                                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Lifecycle Methods ---

  @override
  void dispose() {
    // Dispose controllers to free up resources when the widget is removed.
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
