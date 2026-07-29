/// Whether the app should wire the in-memory mock repositories instead of
/// the Firebase-backed ones.
///
/// Defaults to `false` (real Firebase). Override at build/run time with
/// `--dart-define=USE_MOCK_REPOSITORIES=true` to develop the UI without a
/// Firebase project available. Read once at the provider level — see
/// `useMockRepositoriesProvider` — rather than scattered through the app, so
/// there is exactly one place that decides which backend is live.
const bool useMockRepositories = bool.fromEnvironment(
  'USE_MOCK_REPOSITORIES',
  defaultValue: false,
);
