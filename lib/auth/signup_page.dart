import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_page.dart';
import '../ui elements/slide_transition.dart';
import '../ui elements/social_sign_in_button.dart';


class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[850],
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24.0),
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8.0),
                const Text(
                  'Join us and start listening.',
                  style: TextStyle(
                    fontSize: 16.0,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32.0),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[700],
                    hintText: 'Enter your name',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[700],
                    hintText: 'Enter your email',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[700],
                    hintText: 'Enter your password',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[700],
                    hintText: 'Confirm your password',
                    hintStyle: const TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32.0),
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 18.0,
                            color: Colors.black,
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
                const SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SocialSignInButton(
                      imagePath: 'images/google_logo.png',
                      onTap: () {
                        // TODO: Implement Google sign-in
                      },
                    ),
                    const SizedBox(width: 24),
                    SocialSignInButton(
                      imagePath: 'images/facebook_logo.png',
                      onTap: () {
                        // TODO: Implement Facebook sign-in
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24.0),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      SlideRightRoute(page: const LoginPage()),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: Colors.white70),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }

  void _signUp() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match.';
        _isLoading = false;
      });
      return;
    }
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // Optionally update display name
      if (_nameController.text.trim().isNotEmpty) {
        await FirebaseAuth.instance.currentUser?.updateDisplayName(_nameController.text.trim());
      }
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'yay success',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
