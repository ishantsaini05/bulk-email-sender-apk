import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  SharedPreferences? _preferences;
  
  Future<SharedPreferences> get _prefs async {
    if (_preferences != null) return _preferences!;
    _preferences = await SharedPreferences.getInstance();
    return _preferences!;
  }
  
  // Token storage
  Future<void> setToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString('auth_token', token);
  }
  
  Future<String?> getToken() async {
    final prefs = await _prefs;
    return prefs.getString('auth_token');
  }
  
  Future<void> deleteToken() async {
    final prefs = await _prefs;
    await prefs.remove('auth_token');
  }
  
  // User data
  Future<void> setUser(String userJson) async {
    final prefs = await _prefs;
    await prefs.setString('user_data', userJson);
  }
  
  Future<String?> getUser() async {
    final prefs = await _prefs;
    return prefs.getString('user_data');
  }
  
  Future<void> deleteUser() async {
    final prefs = await _prefs;
    await prefs.remove('user_data');
  }
  
  // Email config
  Future<void> setEmailConfig(String configJson) async {
    final prefs = await _prefs;
    await prefs.setString('email_config', configJson);
  }
  
  Future<String?> getEmailConfig() async {
    final prefs = await _prefs;
    return prefs.getString('email_config');
  }
  
  Future<void> deleteEmailConfig() async {
    final prefs = await _prefs;
    await prefs.remove('email_config');
  }
  
  // Settings
  Future<void> saveSettings(Map<String, Object> settings) async {
    final prefs = await _prefs;
    await prefs.setString('app_settings', jsonEncode(settings));
  }
  
  Future<Map<String, dynamic>> getSettings() async {
    final prefs = await _prefs;
    final settingsJson = prefs.getString('app_settings');
    if (settingsJson == null) return {};
    try {
      return jsonDecode(settingsJson) as Map<String, dynamic>;
    } catch (e) {
      return {};
    }
  }
  
  // Clear all
  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}