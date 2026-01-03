class AppConstants {
  // API Base URL
  static const String baseUrl = 'http://10.0.2.2:8000'; // For Android Emulator
  // static const String baseUrl = 'http://localhost:8000'; // For iOS Simulator
  
  // API Endpoints
  static const String login = '/api/v1/auth/login';
  static const String signup = '/api/v1/auth/signup';
  static const String emailConfigSetup = '/api/v1/email-config/setup';
  static const String emailConfig = '/api/v1/email-config/';
  static const String sendEmail = '/api/v1/emails/send';
  static const String emailHistory = '/api/v1/emails/history';
  
  // App Constants
  static const String appName = 'Premium Email';
  static const int dailyEmailLimit = 50;
  
  // Validation
  static const int minPasswordLength = 6;
}