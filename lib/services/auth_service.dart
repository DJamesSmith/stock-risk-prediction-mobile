import '../config/api_endpoints.dart';
import '../core/api_client.dart';
import '../core/api_response.dart';
import '../core/json_utils.dart';
import '../models/user.dart';

class AuthService {
  AuthService(this.api);

  final ApiClient api;

  Future<AppUser> login(String usernameOrEmail, String password) async {
    final ApiResponse response = await api.post(
      ApiEndpoints.login,
      body: {'username_or_email': usernameOrEmail, 'password': password},
      public: true,
    );
    final Map<String, dynamic> tokens = asMap(response.dataMap['tokens']);
    await api.tokens.savePair(asString(tokens['access']), asString(tokens['refresh']));
    return AppUser.fromJson(asMap(response.dataMap['user']));
  }

  Future<void> register({
    required String username,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    await api.post(
      ApiEndpoints.register,
      body: {
        'username': username,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      public: true,
    );
  }

  Future<AppUser> me() async {
    final ApiResponse response = await api.get(ApiEndpoints.me);
    return AppUser.fromJson(response.dataMap);
  }

  Future<AppUser> updateProfile({required String username, required String email}) async {
    final ApiResponse response = await api.patch(
      ApiEndpoints.me,
      body: {'username': username, 'email': email},
    );
    return AppUser.fromJson(response.dataMap);
  }

  Future<String> changePassword({
    required String oldPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final ApiResponse response = await api.post(
      ApiEndpoints.changePassword,
      body: {
        'old_password': oldPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
    );
    final Map<String, dynamic> tokens = asMap(response.dataMap['tokens']);
    await api.tokens.savePair(asString(tokens['access']), asString(tokens['refresh']));
    return response.message;
  }

  Future<void> logout() async {
    final String? refresh = api.tokens.refresh;

    if (refresh == null) {
      return;
    }

    await api.post(ApiEndpoints.logout, body: {'refresh': refresh});
  }
}
