import 'package:flutter/material.dart';

void main() {
  runApp(const HamweTripApp());
}

/// Temporary root for the shared project. Feature screens will be added in
/// `lib/features` as the team builds them.
class HamweTripApp extends StatelessWidget {
  const HamweTripApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HamweTrip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF154212)),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('HamweTrip'))),
    );
  }
}
