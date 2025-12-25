/// Centralized config values pulled from --dart-define at runtime.
class AppConfig {
  static const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const firebaseAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const firebaseStorageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');

  static const tmdbApiKey = String.fromEnvironment('TMDB_API_KEY');
  static const youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY');
  static const githubClientId = String.fromEnvironment('GITHUB_CLIENT_ID');
  static const githubTokenEndpoint = String.fromEnvironment('GITHUB_TOKEN_ENDPOINT');

  /// Handy helper in dev to warn when keys are missing.
  static void warnIfMissing() {
    final entries = <String, String?>{
      'FIREBASE_API_KEY': firebaseApiKey,
      'FIREBASE_AUTH_DOMAIN': firebaseAuthDomain,
      'FIREBASE_PROJECT_ID': firebaseProjectId,
      'FIREBASE_STORAGE_BUCKET': firebaseStorageBucket,
      'FIREBASE_MESSAGING_SENDER_ID': firebaseMessagingSenderId,
      'FIREBASE_APP_ID': firebaseAppId,
      'TMDB_API_KEY': tmdbApiKey,
      'YOUTUBE_API_KEY': youtubeApiKey,
      'GITHUB_CLIENT_ID': githubClientId,
      'GITHUB_TOKEN_ENDPOINT': githubTokenEndpoint,
    };
    final missing = entries.entries.where((e) => (e.value ?? '').isEmpty).map((e) => e.key);
    if (missing.isNotEmpty) {
      // ignore: avoid_print
      print('Missing --dart-define values: ${missing.join(', ')}');
    }
  }
}
