import 'package:flutter/material.dart';
import 'marble_selection_screen2.dart';

void main() {
  runApp(const SoccerApp());
}

class SoccerApp extends StatelessWidget {
  const SoccerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soccer Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MarbleSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

