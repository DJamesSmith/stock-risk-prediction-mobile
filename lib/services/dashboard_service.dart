import '../core/api_client.dart';
import '../core/api_response.dart';
import '../core/formatters.dart';
import '../models/dashboard.dart';
import '../models/price.dart';

class DashboardService {
  DashboardService(this.api);

  final ApiClient api;

  Future<InvestorDashboard> investor() async {
    final ApiResponse response = await api.get('/api/dashboard/investor/');
    return InvestorDashboard.fromJson(response.dataMap);
  }

  Future<AnalystDashboard> analyst() async {
    final ApiResponse response = await api.get('/api/dashboard/analyst/');
    return AnalystDashboard.fromJson(response.dataMap);
  }

  Future<AdminDashboard> admin() async {
    final ApiResponse response = await api.get('/api/dashboard/admin/');
    return AdminDashboard.fromJson(response.dataMap);
  }

  Future<HoldingTrend> holdingTrend(int holdingId, {DateTime? start, DateTime? end}) async {
    final Map<String, dynamic> query = {};

    if (start != null) {
      query['start'] = Formatters.apiDate(start);
    }

    if (end != null) {
      query['end'] = Formatters.apiDate(end);
    }

    final ApiResponse response = await api.get('/api/dashboard/holdings/$holdingId/trend/', query: query);
    return HoldingTrend.fromJson(response.dataMap);
  }
}
