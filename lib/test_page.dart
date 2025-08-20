import 'package:firebase_auth/firebase_auth.dart';

import 'auth/login_page.dart';

import 'device_music_page.dart';
import 'core/transitions/page_transitions.dart';
import 'core/demo/transition_demo_page.dart';

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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.logout, color: Colors.white),
                        SizedBox(width: 8),
                        Text('You have been signed out.'),
                      ],
                    ),
                    backgroundColor: Colors.red.withOpacity(0.85),
                  ),
                );
                await Future.delayed(const Duration(milliseconds: 900));
                Navigator.pushAndRemoveUntil(
                  context,
                  PageTransitions.particleDissolve(const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'dev is paused here',
              style: TextStyle(fontSize: 24.0),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.animation),
              label: const Text('Transition Demo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  PageTransitions.circleMorph(const TransitionDemoPage()),
                );
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.library_music),
              label: const Text('Device Music'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  PageTransitions.flip(const DeviceMusicPage(), horizontal: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
