import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _baseUrlFromBuild = String.fromEnvironment('API_BASE_URL');

  static String get baseUrl {
    String url = _baseUrlFromBuild;

    if (url.isEmpty) {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        url = 'http://10.0.2.2:8000';
      } else {
        url = 'http://127.0.0.1:8000';
      }
    }

    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }

    return url;
  }

  static Uri liveUri(String accessToken) {
    final Uri base = Uri.parse(baseUrl);
    final String scheme = base.scheme == 'https' ? 'wss' : 'ws';

    return base.replace(
      scheme: scheme,
      path: '/ws/live/',
      queryParameters: {'token': accessToken},
    );
  }

  static Uri webPage(String path) {
    return Uri.parse(baseUrl).replace(path: path);
  }
}
