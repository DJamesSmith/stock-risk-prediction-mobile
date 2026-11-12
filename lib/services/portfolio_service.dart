import '../config/api_endpoints.dart';
import '../core/api_client.dart';
import '../core/api_response.dart';
import '../models/page_result.dart';
import '../models/portfolio.dart';

class PortfolioService {
  PortfolioService(this.api);

  final ApiClient api;

  Future<PageResult<Portfolio>> list({String? nextUrl}) async {
    final ApiResponse response = await api.get(nextUrl ?? ApiEndpoints.portfolios);
    return PageResult.fromJson(response.dataMap, Portfolio.fromJson);
  }

  Future<Portfolio> detail(int id) async {
    final ApiResponse response = await api.get(ApiEndpoints.portfolioDetail(id));
    return Portfolio.fromJson(response.dataMap);
  }

  Future<PortfolioSummary> summary(int id) async {
    final ApiResponse response = await api.get(ApiEndpoints.portfolioSummary(id));
    return PortfolioSummary.fromJson(response.dataMap);
  }

  Future<Portfolio> create({required String name, required String description}) async {
    final ApiResponse response = await api.post(
      ApiEndpoints.portfolios,
      body: {'name': name, 'description': description},
    );
    return Portfolio.fromJson(response.dataMap);
  }

  Future<Portfolio> update(int id, {required String name, required String description}) async {
    final ApiResponse response = await api.patch(
      ApiEndpoints.portfolioDetail(id),
      body: {'name': name, 'description': description},
    );
    return Portfolio.fromJson(response.dataMap);
  }

  Future<void> remove(int id) async {
    await api.delete(ApiEndpoints.portfolioDetail(id));
  }
}
