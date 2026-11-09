import '../core/json_utils.dart';

class MiniUser {
  MiniUser({required this.id, required this.username});

  final int id;
  final String username;

  factory MiniUser.fromJson(Map<String, dynamic> json) {
    return MiniUser(id: asInt(json['id']), username: asString(json['username']));
  }

  static MiniUser? maybe(dynamic value) {
    if (value is! Map) {
      return null;
    }

    return MiniUser.fromJson(asMap(value));
  }
}

class AppUser {
  AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.assignedAnalyst,
    required this.isActive,
    required this.dateJoined,
  });

  static const String investor = 'investor';
  static const String analyst = 'analyst';
  static const String admin = 'admin';
  static const List<String> roles = [investor, analyst, admin];

  final int id;
  final String username;
  final String email;
  final String role;
  final MiniUser? assignedAnalyst;
  final bool isActive;
  final String? dateJoined;

  bool get isInvestor => role == investor;
  bool get isAnalyst => role == analyst;
  bool get isAdmin => role == admin;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: asInt(json['id']),
      username: asString(json['username']),
      email: asString(json['email']),
      role: asString(json['role']),
      assignedAnalyst: MiniUser.maybe(json['assigned_analyst']),
      isActive: json['is_active'] == true,
      dateJoined: asNullableString(json['date_joined']),
    );
  }
}
