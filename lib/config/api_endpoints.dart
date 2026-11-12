import 'api_config.dart';

class ApiEndpoints {
  static const String register = '/api/accounts/register/';
  static const String login = '/api/accounts/login/';
  static const String tokenRefresh = '/api/accounts/token/refresh/';
  static const String logout = '/api/accounts/logout/';
  static const String me = '/api/accounts/me/';
  static const String changePassword = '/api/accounts/change-password/';
  static const String users = '/api/accounts/users/';
  static String userDetail(int userId) => '/api/accounts/users/$userId/';
  static const String portfolios = '/api/portfolios/';

  static String portfolioDetail(int portfolioId) => '/api/portfolios/$portfolioId/';
  static String portfolioSummary(int portfolioId) => '/api/portfolios/$portfolioId/summary/';
  static String portfolioHoldings(int portfolioId) => '/api/portfolios/$portfolioId/holdings/';
  static String holdingDetail(int holdingId) => '/api/holdings/$holdingId/';
  static String latestPrice(String ticker) => '/api/market/prices/$ticker/';
  static String priceHistory(String ticker) => '/api/market/prices/$ticker/history/';
  static String refreshPrices(String ticker) => '/api/market/refresh/$ticker/';
  static String holdingRisk(int holdingId) => '/api/analytics/holdings/$holdingId/risk/';
  static String holdingForecast(int holdingId) => '/api/analytics/holdings/$holdingId/forecast/';
  static String holdingRecompute(int holdingId) => '/api/analytics/holdings/$holdingId/recompute/';
  static String portfolioRiskSummary(int portfolioId) => '/api/analytics/portfolio/$portfolioId/risk-summary/';
  static String taskStatus(String taskId) => '/api/analytics/tasks/$taskId/';

  static const String investorDashboard = '/api/dashboard/investor/';
  static const String analystDashboard = '/api/dashboard/analyst/';
  static const String adminDashboard = '/api/dashboard/admin/';

  static String holdingTrend(int holdingId) => '/api/dashboard/holdings/$holdingId/trend/';

  static const String liveSocket = '/ws/live/';

  static Uri liveSocketUri(String accessToken) {
    return Uri.parse('${ApiConfig.webSocketBaseUrl}$liveSocket').replace(
      queryParameters: {'token': accessToken},
    );
  }

  static const String datasetsPage = '/datasets/';
  static const String mlTrainingPage = '/ml/';

  static Uri webPage(String path) => Uri.parse('${ApiConfig.baseUrl}$path');
}