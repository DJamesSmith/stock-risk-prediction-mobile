import '../core/json_utils.dart';

class PriceRow {
  PriceRow({
    required this.ticker,
    required this.date,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  final String ticker;
  final String date;
  final double? open;
  final double? high;
  final double? low;
  final double close;
  final int volume;

  factory PriceRow.fromJson(Map<String, dynamic> json) {
    return PriceRow(
      ticker: asString(json['ticker']),
      date: asString(json['date']),
      open: asDouble(json['open_price']),
      high: asDouble(json['high_price']),
      low: asDouble(json['low_price']),
      close: asDouble(json['close_price']) ?? 0,
      volume: asInt(json['volume']),
    );
  }
}

class ChartPoint {
  ChartPoint({required this.date, required this.close});

  final DateTime date;
  final double close;
}

class HoldingTrend {
  HoldingTrend({
    required this.ticker,
    required this.buyPrice,
    required this.buyDate,
    required this.start,
    required this.end,
    required this.points,
  });

  final String ticker;
  final double buyPrice;
  final String buyDate;
  final String start;
  final String end;
  final List<ChartPoint> points;

  factory HoldingTrend.fromJson(Map<String, dynamic> json) {
    final List<ChartPoint> points = [];

    for (final Map<String, dynamic> row in asMapList(json['points'])) {
      final DateTime? date = DateTime.tryParse(asString(row['date']));
      final double? close = asDouble(row['close_price']);

      if (date != null && close != null) {
        points.add(ChartPoint(date: date, close: close));
      }
    }

    return HoldingTrend(
      ticker: asString(json['ticker']),
      buyPrice: asDouble(json['buy_price']) ?? 0,
      buyDate: asString(json['buy_date']),
      start: asString(json['start']),
      end: asString(json['end']),
      points: points,
    );
  }
}
