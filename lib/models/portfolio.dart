import '../core/json_utils.dart';
import 'holding.dart';
import 'risk.dart';
import 'user.dart';

class Portfolio {
  Portfolio({
    required this.id,
    required this.name,
    required this.description,
    required this.owner,
    required this.holdingsCount,
    required this.totalValue,
    required this.holdings,
  });

  final int id;
  final String name;
  final String description;
  final MiniUser? owner;
  final int holdingsCount;
  final double totalValue;
  final List<Holding> holdings;

  factory Portfolio.fromJson(Map<String, dynamic> json) {
    return Portfolio(
      id: asInt(json['id']),
      name: asString(json['name']),
      description: asString(json['description']),
      owner: MiniUser.maybe(json['owner']),
      holdingsCount: asInt(json['holdings_count']),
      totalValue: asDouble(json['total_value']) ?? 0,
      holdings: asMapList(json['holdings']).map(Holding.fromJson).toList(),
    );
  }
}

class HoldingPosition {
  HoldingPosition({
    required this.id,
    required this.ticker,
    required this.quantity,
    required this.buyPrice,
    required this.currentPrice,
    required this.priceDate,
    required this.cost,
    required this.currentValue,
    required this.gainLoss,
    required this.gainLossPercent,
    required this.riskLabel,
  });

  final int id;
  final String ticker;
  final double quantity;
  final double buyPrice;
  final double? currentPrice;
  final String? priceDate;
  final double cost;
  final double currentValue;
  final double gainLoss;
  final double gainLossPercent;
  final String? riskLabel;

  factory HoldingPosition.fromJson(Map<String, dynamic> json) {
    return HoldingPosition(
      id: asInt(json['id']),
      ticker: asString(json['ticker']),
      quantity: asDouble(json['quantity']) ?? 0,
      buyPrice: asDouble(json['buy_price']) ?? 0,
      currentPrice: asDouble(json['current_price']),
      priceDate: asNullableString(json['price_date']),
      cost: asDouble(json['cost']) ?? 0,
      currentValue: asDouble(json['current_value']) ?? 0,
      gainLoss: asDouble(json['gain_loss']) ?? 0,
      gainLossPercent: asDouble(json['gain_loss_percent']) ?? 0,
      riskLabel: asNullableString(json['risk_label']),
    );
  }
}

class PortfolioSummary {
  PortfolioSummary({
    required this.portfolioId,
    required this.portfolioName,
    required this.owner,
    required this.holdingsCount,
    required this.totalCost,
    required this.currentValue,
    required this.gainLoss,
    required this.gainLossPercent,
    required this.riskDistribution,
    required this.holdings,
    required this.generatedAt,
  });

  final int portfolioId;
  final String portfolioName;
  final MiniUser? owner;
  final int holdingsCount;
  final double totalCost;
  final double currentValue;
  final double gainLoss;
  final double gainLossPercent;
  final RiskDistribution riskDistribution;
  final List<HoldingPosition> holdings;
  final String? generatedAt;

  factory PortfolioSummary.fromJson(Map<String, dynamic> json) {
    return PortfolioSummary(
      portfolioId: asInt(json['portfolio_id']),
      portfolioName: asString(json['portfolio_name']),
      owner: MiniUser.maybe(json['owner']),
      holdingsCount: asInt(json['holdings_count']),
      totalCost: asDouble(json['total_cost']) ?? 0,
      currentValue: asDouble(json['current_value']) ?? 0,
      gainLoss: asDouble(json['unrealised_gain_loss']) ?? 0,
      gainLossPercent: asDouble(json['unrealised_gain_loss_percent']) ?? 0,
      riskDistribution: RiskDistribution.fromJson(asMap(json['risk_distribution'])),
      holdings: asMapList(json['holdings']).map(HoldingPosition.fromJson).toList(),
      generatedAt: asNullableString(json['generated_at']),
    );
  }
}
