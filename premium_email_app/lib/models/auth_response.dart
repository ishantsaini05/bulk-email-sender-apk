// lib/models/auth_response.dart
import 'user.dart';

class AuthResponse {
  final String? accessToken;
  final String? tokenType;
  final User? user;
  final bool success;
  final String? error;

  AuthResponse({
    this.accessToken,
    this.tokenType,
    this.user,
    required this.success,
    this.error,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'],
      tokenType: json['token_type'],
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      success: json['success'] ?? false,
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user?.toJson(),
      'success': success,
      'error': error,
    };
  }
}