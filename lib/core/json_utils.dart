Map<String, dynamic> asMap(dynamic value) {
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return <String, dynamic>{};
}

List<dynamic> asList(dynamic value) {
  if (value is List) {
    return value;
  }

  return const [];
}

List<Map<String, dynamic>> asMapList(dynamic value) {
  return asList(value).map(asMap).toList();
}

int asInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse('${value ?? ''}') ?? 0;
}

double? asDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

String asString(dynamic value) {
  if (value == null) {
    return '';
  }

  return value.toString();
}

String? asNullableString(dynamic value) {
  if (value == null) {
    return null;
  }

  final String text = value.toString();
  return text.isEmpty ? null : text;
}
