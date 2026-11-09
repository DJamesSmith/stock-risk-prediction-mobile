import '../core/json_utils.dart';

class PageResult<T> {
  PageResult({required this.count, required this.next, required this.results});

  final int count;
  final String? next;
  final List<T> results;

  factory PageResult.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic> item) parse) {
    return PageResult(
      count: asInt(json['count']),
      next: asNullableString(json['next']),
      results: asMapList(json['results']).map(parse).toList(),
    );
  }
}
