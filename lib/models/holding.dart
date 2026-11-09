import '../core/json_utils.dart';

class Holding {
  Holding({
    required this.id,
    required this.portfolioId,
    required this.ticker,
    required this.quantity,
    required this.buyPrice,
    required this.buyDate,
    required this.currentPrice,
    required this.riskLabel,
    required this.riskScore,
    required this.predictedDirection,
    required this.predictionConfidence,
    required this.lastPredictedAt,
    required this.riskModelVersion,
    required this.forecastModelVersion,
  });

  final int id;
  final int portfolioId;
  final String ticker;
  final double quantity;
  final double buyPrice;
  final String buyDate;
  final double? currentPrice;
  final String? riskLabel;
  final double? riskScore;
  final String? predictedDirection;
  final double? predictionConfidence;
  final String? lastPredictedAt;
  final String riskModelVersion;
  final String forecastModelVersion;

  double get cost => quantity * buyPrice;

  factory Holding.fromJson(Map<String, dynamic> json) {
    return Holding(
      id: asInt(json['id']),
      portfolioId: asInt(json['portfolio']),
      ticker: asString(json['ticker']),
      quantity: asDouble(json['quantity']) ?? 0,
      buyPrice: asDouble(json['buy_price']) ?? 0,
      buyDate: asString(json['buy_date']),
      currentPrice: asDouble(json['current_price']),
      riskLabel: asNullableString(json['risk_label']),
      riskScore: asDouble(json['risk_score']),
      predictedDirection: asNullableString(json['predicted_direction']),
      predictionConfidence: asDouble(json['prediction_confidence']),
      lastPredictedAt: asNullableString(json['last_predicted_at']),
      riskModelVersion: asString(json['risk_model_version']),
      forecastModelVersion: asString(json['forecast_model_version']),
    );
  }
}
