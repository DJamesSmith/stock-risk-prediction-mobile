import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? access;
  String? refresh;

  bool get hasTokens => access != null && refresh != null;

  Future<void> load() async {
    try {
      access = await _storage.read(key: _accessKey);
      refresh = await _storage.read(key: _refreshKey);
    } catch (_) {
      await clear();
    }
  }

  Future<void> savePair(String accessToken, String refreshToken) async {
    access = accessToken;
    refresh = refreshToken;
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<void> saveAccess(String accessToken) async {
    access = accessToken;
    await _storage.write(key: _accessKey, value: accessToken);
  }

  Future<void> clear() async {
    access = null;
    refresh = null;

    try {
      await _storage.delete(key: _accessKey);
      await _storage.delete(key: _refreshKey);
    } catch (_) {}
  }
}
