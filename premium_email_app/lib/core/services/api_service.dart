// lib/core/services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:premium_email_app/core/constants/api_endpoints.dart';
import 'package:premium_email_app/core/utils/storage.dart';

class ApiService {
  final String baseUrl = ApiEndpoints.baseUrl;
  final StorageService _storage = StorageService();

  Future<Map<String, dynamic>> _request(
    String method,
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? query,
    bool requiresAuth = true,
  }) async {
    try {
      String? token;
      if (requiresAuth) {
        token = await _storage.getToken();
      }

      Uri uri = Uri.parse('$baseUrl$endpoint');
      
      // Add query parameters
      if (query != null) {
        uri = uri.replace(queryParameters: query);
      }

      final headers = {
        'Content-Type': 'application/json',
        if (requiresAuth && token != null) 'Authorization': 'Bearer $token',
      };

      http.Response response;

      switch (method) {
        case 'GET':
          response = await http.get(uri, headers: headers);
          break;
        case 'POST':
          response = await http.post(
            uri,
            headers: headers,
            body: json.encode(data),
          );
          break;
        case 'PUT':
          response = await http.put(
            uri,
            headers: headers,
            body: json.encode(data),
          );
          break;
        case 'DELETE':
          response = await http.delete(uri, headers: headers);
          break;
        default:
          throw Exception('Invalid HTTP method');
      }

      final responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        throw Exception(responseData['detail'] ?? 'Request failed');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? query,
    bool requiresAuth = true,
  }) async {
    return await _request('GET', endpoint, query: query, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    bool requiresAuth = true,
  }) async {
    return await _request('POST', endpoint, data: data, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? data,
    bool requiresAuth = true,
  }) async {
    return await _request('PUT', endpoint, data: data, requiresAuth: requiresAuth);
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    bool requiresAuth = true,
  }) async {
    return await _request('DELETE', endpoint, requiresAuth: requiresAuth);
  }
}