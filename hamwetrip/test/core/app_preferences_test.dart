import 'package:flutter_test/flutter_test.dart';
import 'package:hamwetrip/core/preferences/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The device-scoped settings, and the thing that actually matters about them:
/// that a value written in one session is still there in the next.
void main() {
  /// Builds a fresh [AppPreferences] over the given stored values, standing in
  /// for the app starting up and reading what a previous run left behind.
  Future<AppPreferences> loadWith(Map<String, Object> stored) async {
    SharedPreferences.setMockInitialValues(stored);
    return AppPreferences(await SharedPreferences.getInstance());
  }

  group('defaults on a first launch', () {
    test('onboarding has not been seen', () async {
      final prefs = await loadWith({});
      expect(prefs.hasSeenOnboarding, isFalse);
    });

    test('there is no remembered trip', () async {
      final prefs = await loadWith({});
      expect(prefs.lastOpenedTripId, isNull);
    });

    test(
      'notifications default to on, matching the profile document',
      () async {
        final prefs = await loadWith({});
        expect(prefs.notificationsEnabled, isTrue);
      },
    );
  });

  group('values survive a restart', () {
    test('hasSeenOnboarding', () async {
      final first = await loadWith({});
      await first.setHasSeenOnboarding(true);

      // A second instance over the same store is what the next launch sees.
      final next = AppPreferences(await SharedPreferences.getInstance());
      expect(next.hasSeenOnboarding, isTrue);
    });

    test('lastOpenedTripId', () async {
      final first = await loadWith({});
      await first.setLastOpenedTripId('t_nyungwe');

      final next = AppPreferences(await SharedPreferences.getInstance());
      expect(next.lastOpenedTripId, 't_nyungwe');
    });

    test('notificationsEnabled', () async {
      final first = await loadWith({});
      await first.setNotificationsEnabled(false);

      final next = AppPreferences(await SharedPreferences.getInstance());
      expect(next.notificationsEnabled, isFalse);
    });
  });

  group('reading what a previous run stored', () {
    test('all three are restored together', () async {
      final prefs = await loadWith({
        'hasSeenOnboarding': true,
        'lastOpenedTripId': 't_kivu',
        'notificationsEnabled': false,
      });

      expect(prefs.hasSeenOnboarding, isTrue);
      expect(prefs.lastOpenedTripId, 't_kivu');
      expect(prefs.notificationsEnabled, isFalse);
    });

    test(
      'an empty trip id reads as none rather than an empty string',
      () async {
        // Otherwise the home screen would look for a trip whose id is ''.
        final prefs = await loadWith({'lastOpenedTripId': ''});
        expect(prefs.lastOpenedTripId, isNull);
      },
    );
  });

  group('signing out', () {
    test('forgets the trip and the notification setting', () async {
      final prefs = await loadWith({
        'hasSeenOnboarding': true,
        'lastOpenedTripId': 't_kivu',
        'notificationsEnabled': false,
      });

      await prefs.clearForSignOut();

      expect(prefs.lastOpenedTripId, isNull);
      expect(prefs.notificationsEnabled, isTrue, reason: 'back to the default');
    });

    test('keeps hasSeenOnboarding', () async {
      // Onboarding explains the app, not the account, so the next person to use
      // this device should not be shown it again.
      final prefs = await loadWith({
        'hasSeenOnboarding': true,
        'lastOpenedTripId': 't_kivu',
      });

      await prefs.clearForSignOut();

      expect(prefs.hasSeenOnboarding, isTrue);
    });
  });
}
