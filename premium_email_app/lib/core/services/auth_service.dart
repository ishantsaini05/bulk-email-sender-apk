import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:premium_email_app/core/constants/api_endpoints.dart';
import 'package:premium_email_app/core/services/storage_service.dart';
import 'package:premium_email_app/models/auth_response.dart';
import 'package:premium_email_app/models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  
  final StorageService _storage = StorageService();
  final http.Client _client = http.Client();
  
  // ✅ CHECK TOKEN EXPIRY
  Future<bool> isTokenExpired() async {
    try {
      final token = await _storage.getToken();
      
      if (token == null || token.isEmpty) {
        print('❌ No token found - considered expired');
        return true;
      }
      
      bool expired = JwtDecoder.isExpired(token);
      
      if (expired) {
        print('⏰ Token expired, logging out...');
        await logout();
      } else {
        final expiryDate = JwtDecoder.getExpirationDate(token);
        final timeLeft = expiryDate.difference(DateTime.now());
        print('✅ Token valid for ${timeLeft.inDays} days ${timeLeft.inHours % 24} hours');
      }
      
      return expired;
      
    } catch (e) {
      print('❌ Error checking token expiry: $e');
      return true;
    }
  }
  
  // ✅ GET TOKEN WITH EXPIRY CHECK
  Future<String?> getValidToken() async {
    try {
      final token = await _storage.getToken();
      
      if (token == null || token.isEmpty) {
        return null;
      }
      
      if (JwtDecoder.isExpired(token)) {
        print('⏰ Token expired, clearing...');
        await logout();
        return null;
      }
      
      return token;
      
    } catch (e) {
      print('❌ Error getting valid token: $e');
      return null;
    }
  }
  
  // ✅ LOGOUT FUNCTION
  Future<void> logout() async {
    print('🔓 Logging out...');
    try {
      await _storage.clearAll();
      _client.close();
      print('✅ Logout completed successfully');
    } catch (e) {
      print('❌ Error during logout: $e');
      try {
        await _storage.clearAll();
      } catch (_) {}
    }
  }
  
  // ✅ IS LOGGED IN WITH EXPIRY CHECK
  Future<bool> isLoggedIn() async {
    try {
      final token = await _storage.getToken();
      
      if (token == null || token.isEmpty) {
        return false;
      }
      
      if (JwtDecoder.isExpired(token)) {
        print('⏰ Token expired, auto logout');
        await logout();
        return false;
      }
      
      return true;
      
    } catch (e) {
      print('❌ Error checking login status: $e');
      return false;
    }
  }
  
  // ✅ GET CURRENT USER WITH TOKEN CHECK
  Future<User?> getCurrentUser() async {
    try {
      final isLoggedIn = await this.isLoggedIn();
      if (!isLoggedIn) {
        return null;
      }
      
      final userJson = await _storage.getUser();
      if (userJson != null) {
        final userMap = jsonDecode(userJson);
        return User.fromJson(userMap);
      }
      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
  
  // ✅ FORCE LOGOUT
  Future<void> forceLogoutAndRedirect() async {
    print('🚨 Force logout triggered');
    await logout();
  }
  
  // ✅ FIXED: SIGNUP FUNCTION WITH RETURN STATEMENT
  Future<AuthResponse> signup({
    required String name,
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print('Calling signup API: ${ApiEndpoints.signup}');
      
      final response = await _client.post(
        Uri.parse(ApiEndpoints.signup),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 30));
      
      print('Signup Response Status: ${response.statusCode}');
      print('Signup Response Body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(responseData);
        
        if (authResponse.accessToken != null) {
          await _storage.setToken(authResponse.accessToken!);
        }

        if (authResponse.user != null) {
          await _storage.setUser(jsonEncode(authResponse.user!.toJson()));
        }
        
        return authResponse; // ✅ RETURN STATEMENT
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Signup failed with status ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Invalid response format: $e');
    } catch (e) {
      throw Exception('Signup error: $e');
    }
  }
  
  // ✅ FIXED: LOGIN FUNCTION WITH RETURN STATEMENT
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Calling login API: ${ApiEndpoints.login}');
      
      final response = await _client.post(
        Uri.parse(ApiEndpoints.login),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: 'username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
      ).timeout(const Duration(seconds: 30));
      
      print('Login Response Status: ${response.statusCode}');
      print('Login Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final authResponse = AuthResponse.fromJson(responseData);
        
        if (authResponse.accessToken != null) {
          await _storage.setToken(authResponse.accessToken!);
        }

        if (authResponse.user != null) {
          await _storage.setUser(jsonEncode(authResponse.user!.toJson()));
        }
        
        return authResponse; // ✅ RETURN STATEMENT
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Login failed with status ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error: ${e.message}');
    } on FormatException catch (e) {
      throw Exception('Invalid response format: $e');
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }
  
  // ✅ GET TOKEN
  Future<String?> getToken() async {
    return await _storage.getToken();
  }
}