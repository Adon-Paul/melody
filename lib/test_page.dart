import 'package:firebase_auth/firebase_auth.dart';

import 'auth/login_page.dart';
import 'ui elements/glass_toast.dart';

import 'package:flutter/material.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                GlassToast.show(
                  context,
                  message: 'You have been signed out.',
                  backgroundColor: Colors.red.withOpacity(0.85),
                  icon: Icons.logout,
                );
                await Future.delayed(const Duration(milliseconds: 900));
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'dev is paused here',
          style: TextStyle(fontSize: 24.0),
        ),
      ),
    );
  }
}
