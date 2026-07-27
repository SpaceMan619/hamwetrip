import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/home/presentation/home_screen.dart';

class HamweTripApp extends StatelessWidget {
  const HamweTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HamweTrip',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
