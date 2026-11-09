import '../core/json_utils.dart';
import 'risk.dart';
import 'user.dart';

class MoneyTotals {
  MoneyTotals({
    required this.totalCost,
    required this.currentValue,
    required this.gainLoss,
    required this.gainLossPercent,
  });

  final double totalCost;
  final double currentValue;
  final double gainLoss;
  final double gainLossPercent;

  factory MoneyTotals.fromJson(Map<String, dynamic> json) {
    return MoneyTotals(
      totalCost: asDouble(json['total_cost']) ?? 0,
      currentValue: asDouble(json['current_value']) ?? 0,
      gainLoss: asDouble(json['gain_loss']) ?? 0,
      gainLossPercent: asDouble(json['gain_loss_percent']) ?? 0,
    );
  }
}

class PortfolioRow {
  PortfolioRow({required this.id, required this.name, required this.holdingsCount, required this.totals});

  final int id;
  final String name;
  final int holdingsCount;
  final MoneyTotals totals;

  factory PortfolioRow.fromJson(Map<String, dynamic> json) {
    return PortfolioRow(
      id: asInt(json['id']),
      name: asString(json['name']),
      holdingsCount: asInt(json['holdings_count']),
      totals: MoneyTotals.fromJson(json),
    );
  }
}

class InvestorDashboard {
  InvestorDashboard({
    required this.totals,
    required this.portfolioCount,
    required this.holdingCount,
    required this.riskDistribution,
    required this.portfolios,
    required this.generatedAt,
  });

  final MoneyTotals totals;
  final int portfolioCount;
  final int holdingCount;
  final RiskDistribution riskDistribution;
  final List<PortfolioRow> portfolios;
  final String? generatedAt;

  factory InvestorDashboard.fromJson(Map<String, dynamic> json) {
    return InvestorDashboard(
      totals: MoneyTotals.fromJson(json),
      portfolioCount: asInt(json['portfolio_count']),
      holdingCount: asInt(json['holding_count']),
      riskDistribution: RiskDistribution.fromJson(asMap(json['risk_distribution'])),
      portfolios: asMapList(json['portfolios']).map(PortfolioRow.fromJson).toList(),
      generatedAt: asNullableString(json['generated_at']),
    );
  }
}

class ClientRow {
  ClientRow({
    required this.id,
    required this.username,
    required this.email,
    required this.portfolioCount,
    required this.holdingCount,
    required this.riskDistribution,
    required this.totals,
  });

  final int id;
  final String username;
  final String email;
  final int portfolioCount;
  final int holdingCount;
  final RiskDistribution riskDistribution;
  final MoneyTotals totals;

  factory ClientRow.fromJson(Map<String, dynamic> json) {
    return ClientRow(
      id: asInt(json['id']),
      username: asString(json['username']),
      email: asString(json['email']),
      portfolioCount: asInt(json['portfolio_count']),
      holdingCount: asInt(json['holding_count']),
      riskDistribution: RiskDistribution.fromJson(asMap(json['risk_distribution'])),
      totals: MoneyTotals.fromJson(json),
    );
  }
}

class HighRiskRow {
  HighRiskRow({
    required this.holdingId,
    required this.ticker,
    required this.portfolioName,
    required this.investor,
    required this.currentValue,
    required this.riskScore,
    required this.predictedDirection,
  });

  final int holdingId;
  final String ticker;
  final String portfolioName;
  final MiniUser? investor;
  final double currentValue;
  final double? riskScore;
  final String? predictedDirection;

  factory HighRiskRow.fromJson(Map<String, dynamic> json) {
    return HighRiskRow(
      holdingId: asInt(json['holding_id']),
      ticker: asString(json['ticker']),
      portfolioName: asString(json['portfolio_name']),
      investor: MiniUser.maybe(json['investor']),
      currentValue: asDouble(json['current_value']) ?? 0,
      riskScore: asDouble(json['risk_score']),
      predictedDirection: asNullableString(json['predicted_direction']),
    );
  }
}

class AnalystDashboard {
  AnalystDashboard({
    required this.totals,
    required this.clientCount,
    required this.portfolioCount,
    required this.holdingCount,
    required this.riskDistribution,
    required this.clients,
    required this.highRiskCount,
    required this.highRiskHoldings,
  });

  final MoneyTotals totals;
  final int clientCount;
  final int portfolioCount;
  final int holdingCount;
  final RiskDistribution riskDistribution;
  final List<ClientRow> clients;
  final int highRiskCount;
  final List<HighRiskRow> highRiskHoldings;

  factory AnalystDashboard.fromJson(Map<String, dynamic> json) {
    return AnalystDashboard(
      totals: MoneyTotals.fromJson(json),
      clientCount: asInt(json['client_count']),
      portfolioCount: asInt(json['portfolio_count']),
      holdingCount: asInt(json['holding_count']),
      riskDistribution: RiskDistribution.fromJson(asMap(json['risk_distribution'])),
      clients: asMapList(json['clients']).map(ClientRow.fromJson).toList(),
      highRiskCount: asInt(json['high_risk_count']),
      highRiskHoldings: asMapList(json['high_risk_holdings']).map(HighRiskRow.fromJson).toList(),
    );
  }
}

class ModelInfo {
  ModelInfo({
    required this.version,
    required this.algorithm,
    required this.trainedAt,
    required this.tickersCount,
    required this.testMetrics,
    required this.comparison,
  });

  final String version;
  final String? algorithm;
  final String? trainedAt;
  final int tickersCount;
  final Map<String, double> testMetrics;
  final String? comparison;

  static ModelInfo? maybe(dynamic value) {
    if (value is! Map) {
      return null;
    }

    final Map<String, dynamic> json = asMap(value);
    final Map<String, double> metrics = {};

    asMap(json['test_metrics']).forEach((key, metric) {
      final double? number = asDouble(metric);

      if (metric is num && number != null) {
        metrics[key] = number;
      }
    });

    return ModelInfo(
      version: asString(json['version']),
      algorithm: asNullableString(json['algorithm']),
      trainedAt: asNullableString(json['trained_at']),
      tickersCount: asInt(json['tickers_count']),
      testMetrics: metrics,
      comparison: asNullableString(json['comparison']),
    );
  }
}

class AdminDashboard {
  AdminDashboard({
    required this.totalUsers,
    required this.investors,
    required this.analysts,
    required this.admins,
    required this.portfolioCount,
    required this.holdingCount,
    required this.tickersTracked,
    required this.lastIngestedAt,
    required this.latestPriceDate,
    required this.riskModel,
    required this.forecastModel,
    required this.riskDistribution,
  });

  final int totalUsers;
  final int investors;
  final int analysts;
  final int admins;
  final int portfolioCount;
  final int holdingCount;
  final int tickersTracked;
  final String? lastIngestedAt;
  final String? latestPriceDate;
  final ModelInfo? riskModel;
  final ModelInfo? forecastModel;
  final RiskDistribution riskDistribution;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> users = asMap(json['users']);
    final Map<String, dynamic> marketData = asMap(json['market_data']);
    final Map<String, dynamic> models = asMap(json['models']);

    return AdminDashboard(
      totalUsers: asInt(users['total']),
      investors: asInt(users['investor']),
      analysts: asInt(users['analyst']),
      admins: asInt(users['admin']),
      portfolioCount: asInt(json['portfolio_count']),
      holdingCount: asInt(json['holding_count']),
      tickersTracked: asInt(json['tickers_tracked']),
      lastIngestedAt: asNullableString(marketData['last_ingested_at']),
      latestPriceDate: asNullableString(marketData['latest_price_date']),
      riskModel: ModelInfo.maybe(models['risk']),
      forecastModel: ModelInfo.maybe(models['forecast']),
      riskDistribution: RiskDistribution.fromJson(asMap(json['risk_distribution'])),
    );
  }
}
