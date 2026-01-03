class EmailConfig {
  final int id;
  final int userId;
  final String emailProvider;
  final String emailAddress;
  final DateTime createdAt;

  EmailConfig({
    required this.id,
    required this.userId,
    required this.emailProvider,
    required this.emailAddress,
    required this.createdAt,
  });

  factory EmailConfig.fromJson(Map<String, dynamic> json) {
    return EmailConfig(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      emailProvider: json['email_provider'] ?? '',
      emailAddress: json['email_address'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'email_provider': emailProvider,
      'email_address': emailAddress,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // For API requests when setting up email
  Map<String, dynamic> toApiJson(String appPassword) {
    return {
      'email_provider': emailProvider,
      'email_address': emailAddress,
      'app_password': appPassword,
    };
  }
}