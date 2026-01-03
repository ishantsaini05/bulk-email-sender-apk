class ApiEndpoints {
  static const String baseUrl = 'http://192.168.1.11:8000';
  
  // Authentication
  static const String signup = '$baseUrl/api/v1/auth/signup';
  static const String login = '$baseUrl/api/v1/auth/login';
  static const String me = '$baseUrl/api/v1/auth/me';
  
  // Email Configuration
  static const String emailConfigSetup = '$baseUrl/api/v1/email-config/setup';
  static const String emailConfigGet = '$baseUrl/api/v1/email-config/';
  static const String emailConfigTest = '$baseUrl/api/v1/email-config/test';
  static const String emailConfigDelete = '$baseUrl/api/v1/email-config/';
  
  // Email Sending
  static const String sendEmail = '$baseUrl/api/v1/emails/send';
  static const String emailHistory = '$baseUrl/api/v1/emails/history';
  
  // Health
  static const String health = '$baseUrl/health';
  
  // Helper method to get full URL
  static String endpoint(String path) {
    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }
    return '$baseUrl/$path';
  }
}