import '../core/json_utils.dart';

class RiskDistribution {
  RiskDistribution({required this.low, required this.medium, required this.high, required this.notRated});

  final int low;
  final int medium;
  final int high;
  final int notRated;

  int get total => low + medium + high + notRated;

  factory RiskDistribution.fromJson(Map<String, dynamic> json) {
    return RiskDistribution(
      low: asInt(json['low']),
      medium: asInt(json['medium']),
      high: asInt(json['high']),
      notRated: asInt(json['not_rated']),
    );
  }
}

class DirectionDistribution {
  DirectionDistribution({required this.up, required this.down, required this.notPredicted});

  final int up;
  final int down;
  final int notPredicted;

  factory DirectionDistribution.fromJson(Map<String, dynamic> json) {
    return DirectionDistribution(
      up: asInt(json['up']),
      down: asInt(json['down']),
      notPredicted: asInt(json['not_predicted']),
    );
  }
}

class HoldingRisk {
  HoldingRisk({
    required this.riskLabel,
    required this.riskScore,
    required this.lastPredictedAt,
    required this.modelVersion,
    required this.holdingAgeDays,
    required this.unrealisedGainLossPercent,
  });

  final String? riskLabel;
  final double? riskScore;
  final String? lastPredictedAt;
  final String modelVersion;
  final int holdingAgeDays;
  final double? unrealisedGainLossPercent;

  factory HoldingRisk.fromJson(Map<String, dynamic> json) {
    return HoldingRisk(
      riskLabel: asNullableString(json['risk_label']),
      riskScore: asDouble(json['risk_score']),
      lastPredictedAt: asNullableString(json['last_predicted_at']),
      modelVersion: asString(json['model_version']),
      holdingAgeDays: asInt(json['holding_age_days']),
      unrealisedGainLossPercent: asDouble(json['unrealised_gain_loss_percent']),
    );
  }
}

class PortfolioRiskSummary {
  PortfolioRiskSummary({
    required this.totalValue,
    required this.riskDistribution,
    required this.directionDistribution,
    required this.averageConfidence,
    required this.averageForecastConfidence,
  });

  final double totalValue;
  final RiskDistribution riskDistribution;
  final DirectionDistribution directionDistribution;
  final double? averageConfidence;
  final double? averageForecastConfidence;

  factory PortfolioRiskSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioRiskSummary(
      totalValue: asDouble(json['total_value']) ?? 0,
      riskDistribution: RiskDistribution.fromJson(asMap(json['risk_distribution'])),
      directionDistribution: DirectionDistribution.fromJson(asMap(json['direction_distribution'])),
      averageConfidence: asDouble(json['average_confidence']),
      averageForecastConfidence: asDouble(json['average_forecast_confidence']),
    );
  }
}
