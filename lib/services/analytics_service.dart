import '../core/api_client.dart';
import '../core/api_response.dart';
import '../core/json_utils.dart';
import '../models/forecast.dart';
import '../models/risk.dart';

class AnalyticsService {
  AnalyticsService(this.api);

  final ApiClient api;

  Future<HoldingRisk> holdingRisk(int holdingId) async {
    final ApiResponse response = await api.get('/api/analytics/holdings/$holdingId/risk/');
    return HoldingRisk.fromJson(response.dataMap);
  }

  Future<HoldingForecast> holdingForecast(int holdingId) async {
    final ApiResponse response = await api.get('/api/analytics/holdings/$holdingId/forecast/');
    return HoldingForecast.fromJson(response.dataMap);
  }

  Future<PortfolioRiskSummary> portfolioRiskSummary(int portfolioId) async {
    final ApiResponse response = await api.get('/api/analytics/portfolio/$portfolioId/risk-summary/');
    return PortfolioRiskSummary.fromJson(response.dataMap);
  }

  Future<String> recompute(int holdingId) async {
    final ApiResponse response = await api.post('/api/analytics/holdings/$holdingId/recompute/');
    return asString(response.dataMap['task_id']);
  }

  Future<TaskStatus> taskStatus(String taskId) async {
    final ApiResponse response = await api.get('/api/analytics/tasks/$taskId/');
    return TaskStatus.fromJson(response.dataMap);
  }
}
