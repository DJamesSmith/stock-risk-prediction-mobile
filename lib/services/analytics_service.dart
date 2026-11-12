import '../config/api_endpoints.dart';
import '../core/api_client.dart';
import '../core/api_response.dart';
import '../core/json_utils.dart';
import '../models/forecast.dart';
import '../models/risk.dart';

class AnalyticsService {
  AnalyticsService(this.api);

  final ApiClient api;

  Future<HoldingRisk> holdingRisk(int holdingId) async {
    final ApiResponse response = await api.get(ApiEndpoints.holdingRisk(holdingId));
    return HoldingRisk.fromJson(response.dataMap);
  }

  Future<HoldingForecast> holdingForecast(int holdingId) async {
    final ApiResponse response = await api.get(ApiEndpoints.holdingForecast(holdingId));
    return HoldingForecast.fromJson(response.dataMap);
  }

  Future<PortfolioRiskSummary> portfolioRiskSummary(int portfolioId) async {
    final ApiResponse response = await api.get(ApiEndpoints.portfolioRiskSummary(portfolioId));
    return PortfolioRiskSummary.fromJson(response.dataMap);
  }

  Future<String> recompute(int holdingId) async {
    final ApiResponse response = await api.post(ApiEndpoints.holdingRecompute(holdingId));
    return asString(response.dataMap['task_id']);
  }

  Future<TaskStatus> taskStatus(String taskId) async {
    final ApiResponse response = await api.get(ApiEndpoints.taskStatus(taskId));
    return TaskStatus.fromJson(response.dataMap);
  }
}
