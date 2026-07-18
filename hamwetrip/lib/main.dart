import 'package:flutter/material.dart';
import './features/group_voting/screens/main_shell_screen.dart';

void main() {
  runApp(const HamweTripApp());
}

class HamweTripApp extends StatelessWidget {
  const HamweTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HamweTrip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E), // Teal theme
          brightness: Brightness.light,
        ),
      ),
      home: const MainShellScreen(), // Now opens the Bottom Nav wrapper
    );
  }
}
