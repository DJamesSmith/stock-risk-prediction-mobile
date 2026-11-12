import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/api_config.dart';
import '../config/api_endpoints.dart';
import 'api_response.dart';
import 'json_utils.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient(this.tokens) {
    _dio = Dio(_options());
    _refreshDio = Dio(_options());
    _dio.interceptors.add(InterceptorsWrapper(onRequest: _onRequest, onError: _onError));
  }

  final TokenStorage tokens;
  late final Dio _dio;
  late final Dio _refreshDio;
  Future<bool?>? _refreshing;
  VoidCallback? onSessionExpired;

  BaseOptions _options() {
    return BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );
  }

  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) {
    return _send(() => _dio.get(path, queryParameters: query));
  }

  Future<ApiResponse> post(String path, {Map<String, dynamic>? body, bool public = false}) {
    return _send(() => _dio.post(path, data: body ?? {}, options: Options(extra: {'public': public})));
  }

  Future<ApiResponse> patch(String path, {Map<String, dynamic>? body}) {
    return _send(() => _dio.patch(path, data: body ?? {}));
  }

  Future<ApiResponse> delete(String path) {
    return _send(() => _dio.delete(path));
  }

  Future<ApiResponse> _send(Future<Response<dynamic>> Function() request) async {
    try {
      final Response<dynamic> response = await request();
      return ApiResponse.fromJson(response.data, response.statusCode ?? 200);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  void _onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final bool isPublic = options.extra['public'] == true;
    final String? access = tokens.access;

    if (!isPublic && access != null) {
      options.headers['Authorization'] = 'Bearer $access';
    }

    handler.next(options);
  }

  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    final RequestOptions options = error.requestOptions;
    final bool isUnauthorized = error.response?.statusCode == 401;
    final bool isPublic = options.extra['public'] == true;
    final bool alreadyRetried = options.extra['retried'] == true;

    if (!isUnauthorized || isPublic || alreadyRetried || tokens.refresh == null) {
      handler.next(error);
      return;
    }

    final bool? refreshed = await refreshAccessToken();

    if (refreshed != true) {
      if (refreshed == false) {
        onSessionExpired?.call();
      }

      handler.next(error);
      return;
    }

    options.extra['retried'] = true;

    try {
      final Response<dynamic> response = await _dio.fetch(options);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool?> refreshAccessToken() async {
    final Future<bool?>? running = _refreshing;

    if (running != null) {
      return running;
    }

    final Future<bool?> refreshing = _refresh();
    _refreshing = refreshing;

    try {
      return await refreshing;
    } finally {
      _refreshing = null;
    }
  }

  Future<bool?> _refresh() async {
    final String? refresh = tokens.refresh;

    if (refresh == null) {
      return false;
    }

    try {
      final Response<dynamic> response = await _refreshDio.post(
        ApiEndpoints.tokenRefresh,
        data: {'refresh': refresh},
      );
      final String access = asString(asMap(asMap(response.data)['data'])['access']);

      if (access.isEmpty) {
        return false;
      }

      await tokens.saveAccess(access);
      return true;
    } on DioException catch (error) {
      final int? status = error.response?.statusCode;

      if (status == 400 || status == 401 || status == 403) {
        return false;
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
