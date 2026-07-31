import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/hamwe_trip_app.dart';
import 'core/config/app_config.dart';
import 'core/preferences/app_preferences.dart';
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

  // Loaded before the first frame rather than inside a widget, because the very
  // first routing decision depends on it: someone who has already been through
  // onboarding should never see it flash past on the way to the login screen.
  final preferences = AppPreferences(await SharedPreferences.getInstance());

  // ProviderScope wraps the app root here rather than living inside
  // HamweTripApp, so a widget test can supply its own ProviderScope with
  // overrides (e.g. forcing mock repositories) around HamweTripApp instead of
  // being stuck with whatever this one is configured with.
  runApp(
    ProviderScope(
      overrides: [appPreferencesProvider.overrideWithValue(preferences)],
      child: const HamweTripApp(),
    ),
  );
}
