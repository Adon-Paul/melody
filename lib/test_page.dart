
import 'package:flutter/material.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Page'),
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
