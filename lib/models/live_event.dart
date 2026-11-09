import '../core/api_response.dart';
import '../core/json_utils.dart';

class LiveEvent {
  LiveEvent({
    required this.type,
    required this.status,
    required this.message,
    required this.data,
    required this.errors,
  });

  final String type;
  final String status;
  final String message;
  final Map<String, dynamic> data;
  final Map<String, List<String>> errors;

  int get holdingId => asInt(data['holding_id']);
  int get portfolioId => asInt(data['portfolio_id']);
  String? get taskId => asNullableString(data['task_id']);

  bool get isHoldingEvent => type == 'risk.changed' || type == 'prediction.updated';

  factory LiveEvent.fromJson(Map<String, dynamic> json) {
    return LiveEvent(
      type: asString(json['type']),
      status: asString(json['status']),
      message: asString(json['message']),
      data: asMap(json['data']),
      errors: readErrors(json['errors']),
    );
  }
}

class RiskAlert {
  RiskAlert({
    required this.holdingId,
    required this.portfolioId,
    required this.portfolioName,
    required this.owner,
    required this.ticker,
    required this.riskLabel,
    required this.previousLabel,
    required this.receivedAt,
  });

  final int holdingId;
  final int portfolioId;
  final String portfolioName;
  final String owner;
  final String ticker;
  final String? riskLabel;
  final String? previousLabel;
  final DateTime receivedAt;

  String get headline {
    final String before = previousLabel ?? 'not rated';
    final String after = riskLabel ?? 'not rated';
    return '$ticker: $before → $after';
  }

  bool get isWorse => _rank(riskLabel) > _rank(previousLabel);

  static int _rank(String? label) {
    if (label == 'high') {
      return 3;
    }

    if (label == 'medium') {
      return 2;
    }

    if (label == 'low') {
      return 1;
    }

    return 0;
  }

  factory RiskAlert.fromJson(Map<String, dynamic> json) {
    return RiskAlert(
      holdingId: asInt(json['holding_id']),
      portfolioId: asInt(json['portfolio_id']),
      portfolioName: asString(json['portfolio_name']),
      owner: asString(json['owner']),
      ticker: asString(json['ticker']),
      riskLabel: asNullableString(json['risk_label']),
      previousLabel: asNullableString(json['previous_label']),
      receivedAt: DateTime.now(),
    );
  }
}
