import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'player_selection_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const SoccerApp());
}

class SoccerApp extends StatelessWidget {
  const SoccerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '1:1 축구',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9EB5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const PlayerSelectionScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
