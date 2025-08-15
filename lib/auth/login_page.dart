import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'signup_page.dart';
import '../test_page.dart';
import '../ui elements/slide_transition.dart';
import '../ui elements/social_sign_in_button.dart';


import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32.0),
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Welcome Back',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
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
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
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
              TextField(
                controller: _passwordController,
                obscureText: true,
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SocialSignInButton(
                    imagePath: 'lib/images/google_logo.png',
                    onTap: () {
                      // TODO: Implement Google sign-in
                    },
                  ),
                  const SizedBox(width: 24),
                  SocialSignInButton(
                    imagePath: 'lib/images/facebook_logo.png',
                    onTap: () {
                      // TODO: Implement Facebook sign-in
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
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
              GestureDetector(
                onTap: () {
                  // Navigate to forgot password page
                },
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: Colors.white70),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
  void _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Show toast and navigate to TestPage after successful login
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'yay success',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TestPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
