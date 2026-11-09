import '../core/api_client.dart';
import '../core/api_response.dart';
import '../models/page_result.dart';
import '../models/user.dart';

class UsersService {
  UsersService(this.api);

  final ApiClient api;

  Future<PageResult<AppUser>> list({String? nextUrl}) async {
    final ApiResponse response = await api.get(nextUrl ?? '/api/accounts/users/');
    return PageResult.fromJson(response.dataMap, AppUser.fromJson);
  }

  Future<List<AppUser>> activeAnalysts() async {
    final List<AppUser> analysts = [];
    String? nextUrl;

    do {
      final ApiResponse response;

      if (nextUrl == null) {
        response = await api.get('/api/accounts/users/', query: {'page_size': 100});
      } else {
        response = await api.get(nextUrl);
      }

      final PageResult<AppUser> page = PageResult.fromJson(response.dataMap, AppUser.fromJson);

      for (final AppUser user in page.results) {
        if (user.isAnalyst && user.isActive) {
          analysts.add(user);
        }
      }

      nextUrl = page.next;
    } while (nextUrl != null);

    return analysts;
  }

  Future<AppUser> update(int userId, {required String role, required int? assignedAnalystId}) async {
    final ApiResponse response = await api.patch(
      '/api/accounts/users/$userId/',
      body: {'role': role, 'assigned_analyst': assignedAnalystId},
    );
    return AppUser.fromJson(response.dataMap);
  }
}
