import '../core/json_utils.dart';

class HoldingForecast {
  HoldingForecast({
    required this.predictedDirection,
    required this.predictionConfidence,
    required this.lastPredictedAt,
    required this.modelVersion,
  });

  final String? predictedDirection;
  final double? predictionConfidence;
  final String? lastPredictedAt;
  final String modelVersion;

  factory HoldingForecast.fromJson(Map<String, dynamic> json) {
    return HoldingForecast(
      predictedDirection: asNullableString(json['predicted_direction']),
      predictionConfidence: asDouble(json['prediction_confidence']),
      lastPredictedAt: asNullableString(json['last_predicted_at']),
      modelVersion: asString(json['model_version']),
    );
  }
}

class TaskStatus {
  TaskStatus({required this.taskId, required this.state, required this.ready, required this.error});

  final String taskId;
  final String state;
  final bool ready;
  final String? error;

  bool get succeeded => state == 'SUCCESS';

  factory TaskStatus.fromJson(Map<String, dynamic> json) {
    return TaskStatus(
      taskId: asString(json['task_id']),
      state: asString(json['state']),
      ready: json['ready'] == true,
      error: asNullableString(json['error']),
    );
  }
}
