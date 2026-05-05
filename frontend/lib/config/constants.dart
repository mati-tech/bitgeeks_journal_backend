/// Build-time configuration. Override the API base URL via:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
class AppConstants {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://bitgeeks-journal-backend.onrender.com',
  );

  static const tokenStorageKey = 'auth_token';

  static const mobileBreakpoint = 600.0;
  static const tabletBreakpoint = 1024.0;
  static const desktopBreakpoint = 1440.0;
}

enum ScreenSize { mobile, tablet, desktop }
