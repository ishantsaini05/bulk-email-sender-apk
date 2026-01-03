class User {
  final int id;
  final String name;
  final String email;
  final String status;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.status,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}