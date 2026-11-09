import '../core/api_client.dart';
import '../core/api_response.dart';
import '../models/page_result.dart';
import '../models/portfolio.dart';

class PortfolioService {
  PortfolioService(this.api);

  final ApiClient api;

  Future<PageResult<Portfolio>> list({String? nextUrl}) async {
    final ApiResponse response = await api.get(nextUrl ?? '/api/portfolios/');
    return PageResult.fromJson(response.dataMap, Portfolio.fromJson);
  }

  Future<Portfolio> detail(int id) async {
    final ApiResponse response = await api.get('/api/portfolios/$id/');
    return Portfolio.fromJson(response.dataMap);
  }

  Future<PortfolioSummary> summary(int id) async {
    final ApiResponse response = await api.get('/api/portfolios/$id/summary/');
    return PortfolioSummary.fromJson(response.dataMap);
  }

  Future<Portfolio> create({required String name, required String description}) async {
    final ApiResponse response = await api.post(
      '/api/portfolios/',
      body: {'name': name, 'description': description},
    );
    return Portfolio.fromJson(response.dataMap);
  }

  Future<Portfolio> update(int id, {required String name, required String description}) async {
    final ApiResponse response = await api.patch(
      '/api/portfolios/$id/',
      body: {'name': name, 'description': description},
    );
    return Portfolio.fromJson(response.dataMap);
  }

  Future<void> remove(int id) async {
    await api.delete('/api/portfolios/$id/');
  }
}
