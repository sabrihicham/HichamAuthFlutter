class ApiConfig {
  // Base URL for the API
  static const String baseUrl = 'https://www.freelanci.net/api';

  // API Endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String getUser = '/auth/user';
  static const String updateProfile = '/auth/profile';
  static const String deleteAccount = '/auth/account';
  static const String test = '/test';
  static const String protectedData = '/protected-data';

  // Social Login Endpoints
  static const String socialProviders = '/social/providers';
  static const String socialFacebook = '/auth/social/facebook';
  static const String socialGoogle = '/auth/social/google';
  static const String socialApple = '/auth/social/apple';
  static const String socialFacebookCallback = '/auth/social/facebook/callback';
  static const String socialProfile = '/auth/social/profile';
  static const String socialLogoutAll = '/auth/social/logout-all';
  static const String socialDeleteAccount = '/auth/social/account';
  static const String profile = '/auth/profile';

  // Request timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // Helper methods
  static String getSocialLoginEndpoint(String provider) {
    return '/auth/social/$provider';
  }
}
