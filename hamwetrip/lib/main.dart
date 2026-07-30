import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/hamwe_trip_app.dart';
import 'core/config/app_config.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mock runs skip Firebase entirely, so the UI can be developed without a
  // reachable Firebase project — see core/config/app_config.dart.
  if (!useMockRepositories) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // ProviderScope wraps the app root here rather than living inside
  // HamweTripApp, so a widget test can supply its own ProviderScope with
  // overrides (e.g. forcing mock repositories) around HamweTripApp instead of
  // being stuck with whatever this one is configured with.
  runApp(const ProviderScope(child: HamweTripApp()));
}
