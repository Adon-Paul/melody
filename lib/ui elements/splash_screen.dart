
import 'dart:ui';
import 'package:flutter/material.dart';
import '../auth/login_page.dart'; // Import your login page

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Replicating the "Melody" text style from the image
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(15.0),
              ),
              child: const Text(
                'Melody',
                style: TextStyle(
                  fontFamily: 'serif',
                  color: Colors.green,
                  fontSize: 50.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 200), // Spacer
            // Button with glass effect
            ClipRRect(
              borderRadius: BorderRadius.circular(50.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                child: FloatingActionButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  backgroundColor: Colors.white.withOpacity(0.2), // Semi-transparent white
                  child: const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
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
