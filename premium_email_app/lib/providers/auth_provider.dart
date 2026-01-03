import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:premium_email_app/core/services/auth_service.dart';
import 'package:premium_email_app/core/services/storage_service.dart';
import 'package:premium_email_app/models/auth_response.dart';
import 'package:premium_email_app/models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  User? get currentUser => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  Future<void> login(String email, String password) async {
    _setState(loading: true, error: null);
    
    try {
      final result = await _authService.login(email: email, password: password);
      
      if (result.success) {
        _user = result.user;
        
        // Save user data to storage
        if (_user != null) {
          await _storage.setUser(jsonEncode(_user!.toJson()));
          if (result.accessToken != null) {
            await _storage.setToken(result.accessToken!);
          }
        }
        
        notifyListeners();
      } else {
        _setState(error: result.error ?? "Login failed");
      }
    } catch (e) {
      _setState(error: e.toString());
    } finally {
      _setState(loading: false);
    }
  }

  Future<void> signup(String email, String password, String fullName) async {
    _setState(loading: true, error: null);
    
    try {
      final result = await _authService.signup(
        email: email,
        password: password,
        fullName: fullName,
        name: fullName,
      );
      
      if (result.success) {
        _user = result.user;
        
        // Save user data to storage
        if (_user != null) {
          await _storage.setUser(jsonEncode(_user!.toJson()));
          if (result.accessToken != null) {
            await _storage.setToken(result.accessToken!);
          }
        }
        
        notifyListeners();
      } else {
        _setState(error: result.error ?? "Signup failed");
      }
    } catch (e) {
      _setState(error: e.toString());
    } finally {
      _setState(loading: false);
    }
  }

  Future<void> loadCurrentUser() async {
    try {
      final userData = await _storage.getUser();
      
      if (userData != null && userData.isNotEmpty) {
        final userJson = jsonDecode(userData);
        _user = User.fromJson(userJson);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  // NEW: Helper method to directly get user without async
  Map<String, dynamic>? getCurrentUserData() {
    if (_user != null) {
      return _user!.toJson();
    }
    return null;
  }

  Future<void> logout() async {
    await _authService.logout();
    await _storage.clearAll();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setState({bool? loading, String? error}) {
    if (loading != null) _isLoading = loading;
    if (error != null) _error = error;
    notifyListeners();
  }
}