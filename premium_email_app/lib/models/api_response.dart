// lib/models/api_response.dart
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'error': error,
    };
  }
}

class ApiResult<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResult({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResult.success(T data) {
    return ApiResult(success: true, data: data);
  }

  factory ApiResult.error(String error) {
    return ApiResult(success: false, error: error);
  }
}