import '../core/json_utils.dart';

class LiveQuote {
  LiveQuote({
    required this.ticker,
    required this.price,
    required this.previousClose,
    required this.change,
    required this.changePercent,
    required this.date,
    required this.asOf,
    required this.source,
  });

  final String ticker;
  final double price;
  final double? previousClose;
  final double change;
  final double changePercent;
  final String date;
  final String? asOf;
  final String source;

  bool get isLive => source == 'live';

  String get sourceLabel => isLive ? 'Live' : 'Daily close';

  factory LiveQuote.fromJson(Map<String, dynamic> json) {
    return LiveQuote(
      ticker: asString(json['ticker']).toUpperCase(),
      price: asDouble(json['price']) ?? 0,
      previousClose: asDouble(json['previous_close']),
      change: asDouble(json['change']) ?? 0,
      changePercent: asDouble(json['change_percent']) ?? 0,
      date: asString(json['date']),
      asOf: asNullableString(json['as_of']),
      source: asString(json['source']),
    );
  }
}
