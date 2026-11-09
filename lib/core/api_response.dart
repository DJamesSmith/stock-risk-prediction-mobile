import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'json_utils.dart';

class ApiResponse {
  ApiResponse({
    required this.status,
    required this.message,
    required this.data,
    required this.errors,
    required this.statusCode,
  });

  final String status;
  final String message;
  final dynamic data;
  final Map<String, List<String>> errors;
  final int statusCode;

  Map<String, dynamic> get dataMap => asMap(data);

  factory ApiResponse.fromJson(dynamic json, int statusCode) {
    final Map<String, dynamic> body = asMap(json);

    return ApiResponse(
      status: asString(body['status']),
      message: asString(body['message']),
      data: body['data'],
      errors: readErrors(body['errors']),
      statusCode: statusCode,
    );
  }
}

Map<String, List<String>> readErrors(dynamic value) {
  final Map<String, List<String>> errors = {};

  if (value is! Map) {
    return errors;
  }

  value.forEach((key, messages) {
    if (messages is List) {
      errors[key.toString()] = messages.map((message) => message.toString()).toList();
    } else if (messages != null) {
      errors[key.toString()] = [messages.toString()];
    }
  });

  return errors;
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, Map<String, List<String>>? fieldErrors})
      : fieldErrors = fieldErrors ?? {};

  final String message;
  final int? statusCode;
  final Map<String, List<String>> fieldErrors;

  bool get isNetworkError => statusCode == null;

  String? fieldError(String field) {
    final List<String>? messages = fieldErrors[field];

    if (messages == null || messages.isEmpty) {
      return null;
    }

    return messages.join(' ');
  }

  String get fullMessage {
    final String? general = fieldError('__all__') ?? fieldError('non_field_errors');

    if (general == null) {
      return message;
    }

    return '$message $general';
  }

  factory ApiException.fromDio(DioException error) {
    final Response? response = error.response;

    if (response == null) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return ApiException('The server took too long to answer. Please try again.');
      }

      return ApiException('Cannot reach the server at ${ApiConfig.baseUrl}. Check that Django is running.');
    }

    final ApiResponse body = ApiResponse.fromJson(response.data, response.statusCode ?? 0);
    String message = body.message;

    if (message.isEmpty) {
      message = 'Request failed with status ${response.statusCode}.';
    }

    return ApiException(message, statusCode: response.statusCode, fieldErrors: body.errors);
  }

  @override
  String toString() => message;
}
