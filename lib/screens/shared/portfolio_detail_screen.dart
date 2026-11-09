import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_response.dart';
import '../../core/formatters.dart';
import '../../core/live_socket.dart';
import '../../models/holding.dart';
import '../../models/live_event.dart';
import '../../models/live_quote.dart';
import '../../models/portfolio.dart';
import '../../models/risk.dart';
import '../../models/user.dart';
import '../../services/analytics_service.dart';
import '../../services/portfolio_service.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';
import '../../widgets/direction_badge.dart';
import '../../widgets/live_widgets.dart';
import '../../widgets/money_text.dart';
import '../../widgets/risk_badge.dart';
import '../../widgets/state_views.dart';

class PortfolioDetailScreen extends StatefulWidget {
  const PortfolioDetailScreen({super.key, required this.portfolioId});

  final int portfolioId;

  @override
  State<PortfolioDetailScreen> createState() => _PortfolioDetailScreenState();
}

class _PortfolioDetailScreenState extends State<PortfolioDetailScreen> {
  late final LiveSocket _live;
  StreamSubscription<LiveEvent>? _events;
  Timer? _reloadTimer;
  Set<String> _followed = {};
  Portfolio? _portfolio;
  PortfolioSummary? _summary;
  PortfolioRiskSummary? _risk;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _live = context.read<LiveSocket>();
    _events = _live.events.listen(_onLiveEvent);
    _load();
  }

  @override
  void dispose() {
    _events?.cancel();
    _reloadTimer?.cancel();
    _live.unfollow(_followed);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final List<Object> results = await Future.wait<Object>([
        context.read<PortfolioService>().detail(widget.portfolioId),
        context.read<PortfolioService>().summary(widget.portfolioId),
        context.read<AnalyticsService>().portfolioRiskSummary(widget.portfolioId),
      ]);

      if (!mounted) {
        return;
      }

      final Portfolio portfolio = results[0] as Portfolio;
      _updateFollowed(portfolio.holdings.map((holding) => holding.ticker).toSet());

      setState(() {
        _portfolio = portfolio;
        _summary = results[1] as PortfolioSummary;
        _risk = results[2] as PortfolioRiskSummary;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _error = error.message);

      if (_portfolio != null) {
        showMessage(context, error.message);
      }
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  void _updateFollowed(Set<String> tickers) {
    _live.follow(tickers.difference(_followed));
    _live.unfollow(_followed.difference(tickers));
    _followed = tickers;
  }

  void _onLiveEvent(LiveEvent event) {
    if (event.isHoldingEvent && event.portfolioId == widget.portfolioId) {
      _scheduleReload();
    }
  }

  void _scheduleReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(seconds: 1), _load);
  }

  Future<void> _delete() async {
    final Portfolio? portfolio = _portfolio;

    if (portfolio == null) {
      return;
    }

    final bool confirmed = await confirmAction(
      context,
      title: 'Delete ${portfolio.name}?',
      message: 'The portfolio and all ${portfolio.holdingsCount} holdings in it will be deleted. This cannot be undone.',
    );

    if (!confirmed || !mounted) {
      return;
    }

    try {
      await context.read<PortfolioService>().remove(portfolio.id);

      if (mounted) {
        showMessage(context, 'Portfolio deleted.');
        context.pop(true);
      }
    } on ApiException catch (error) {
      if (mounted) {
        showMessage(context, error.message);
      }
    }
  }

  Future<void> _openAndReload(String path) async {
    await context.push(path);

    if (mounted) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.select<Session, AppUser?>((session) => session.user);
    final Portfolio? portfolio = _portfolio;
    final bool canModify = portfolio != null &&
        user != null &&
        (user.isAdmin || (user.isInvestor && portfolio.owner?.id == user.id));

    return Scaffold(
      appBar: buildAppBar(
        portfolio?.name ?? 'Portfolio',
        actions: [
          if (canModify)
            IconButton(
              tooltip: 'Edit portfolio',
              onPressed: () => _openAndReload('/portfolios/${widget.portfolioId}/edit'),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (canModify)
            IconButton(
              tooltip: 'Delete portfolio',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
      floatingActionButton: canModify
          ? FloatingActionButton.extended(
              onPressed: () => _openAndReload('/portfolios/${widget.portfolioId}/holdings/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add holding'),
            )
          : null,
      body: StateSwitcher(
        loading: _loading,
        error: _error,
        hasData: portfolio != null && _summary != null && _risk != null,
        onRetry: _retry,
        builder: (context) {
          return RefreshIndicator(
            onRefresh: _load,
            child: Consumer<LiveSocket>(
              builder: (context, live, child) {
                return _buildContent(context, live, portfolio!, _summary!, _risk!, user, canModify);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LiveSocket live,
    Portfolio portfolio,
    PortfolioSummary summary,
    PortfolioRiskSummary risk,
    AppUser? user,
    bool canModify,
  ) {
    final TextTheme text = Theme.of(context).textTheme;
    double liveValue = 0;
    double dayChange = 0;
    bool hasLive = false;

    for (final Holding holding in portfolio.holdings) {
      final LiveQuote? quote = live.quoteFor(holding.ticker);
      final double price = quote?.price ?? holding.currentPrice ?? holding.buyPrice;
      liveValue += holding.quantity * price;

      if (quote != null) {
        dayChange += holding.quantity * quote.change;
        hasLive = hasLive || quote.isLive;
      }
    }

    final double gainLoss = liveValue - summary.totalCost;
    final double gainLossPercent = summary.totalCost == 0 ? 0 : gainLoss / summary.totalCost * 100;
    final bool showOwner = user != null && !user.isInvestor && portfolio.owner != null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        CenteredContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LivePausedBar(),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Portfolio value', style: text.labelLarge)),
                          Chip(
                            avatar: Icon(hasLive ? Icons.sensors : Icons.event, size: 16),
                            label: Text(hasLive ? 'Live' : 'Daily close'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      MoneyText(liveValue, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      InfoRow(label: 'Total cost', value: MoneyText(summary.totalCost)),
                      InfoRow(
                        label: 'Unrealised gain / loss',
                        value: MoneyText(gainLoss, signed: true, percent: gainLossPercent),
                      ),
                      InfoRow(label: 'Day change', value: MoneyText(dayChange, signed: true)),
                      if (showOwner) InfoRow(label: 'Owner', value: Text(portfolio.owner!.username)),
                      if (portfolio.description.isNotEmpty) ...[
                        const Divider(height: 24),
                        Text(portfolio.description),
                      ],
                    ],
                  ),
                ),
              ),
              const SectionTitle('Risk overview'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RiskDistributionBar(distribution: risk.riskDistribution),
                      const Divider(height: 24),
                      InfoRow(
                        label: 'Next-day forecast',
                        value: Text(
                          'Up ${risk.directionDistribution.up} · Down ${risk.directionDistribution.down}'
                          ' · None ${risk.directionDistribution.notPredicted}',
                        ),
                      ),
                      InfoRow(
                        label: 'Average risk confidence',
                        value: Text(Formatters.ratioPercent(risk.averageConfidence)),
                      ),
                      InfoRow(
                        label: 'Average forecast confidence',
                        value: Text(Formatters.ratioPercent(risk.averageForecastConfidence)),
                      ),
                    ],
                  ),
                ),
              ),
              SectionTitle('Holdings (${portfolio.holdings.length})'),
              if (portfolio.holdings.isEmpty)
                EmptyView(
                  message: canModify
                      ? 'No holdings yet. Add one to get a risk label and a forecast.'
                      : 'This portfolio has no holdings yet.',
                  icon: Icons.show_chart,
                ),
              for (final Holding holding in portfolio.holdings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _HoldingCard(
                    holding: holding,
                    quote: live.quoteFor(holding.ticker),
                    onTap: () => _openAndReload('/holdings/${holding.id}'),
                  ),
                ),
              const MlDisclaimer(),
            ],
          ),
        ),
      ],
    );
  }
}

class _HoldingCard extends StatelessWidget {
  const _HoldingCard({required this.holding, required this.quote, required this.onTap});

  final Holding holding;
  final LiveQuote? quote;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final double price = quote?.price ?? holding.currentPrice ?? holding.buyPrice;
    final double value = holding.quantity * price;
    final double gainLoss = value - holding.cost;
    final double? dayChange = quote == null ? null : holding.quantity * quote!.change;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(holding.ticker, style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(
                          '${Formatters.quantity(holding.quantity)} @ ${Formatters.money(holding.buyPrice)}',
                          style: text.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        MoneyText(value, style: text.titleSmall),
                        MoneyText(gainLoss, signed: true, style: text.bodySmall),
                        if (dayChange != null)
                          Text('Today ${Formatters.signedMoney(dayChange)}', style: text.bodySmall),
                      ],
                    ),
                  ),
                  LivePriceChip(quote: quote, fallbackPrice: holding.currentPrice),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  RiskBadge(label: holding.riskLabel),
                  DirectionBadge(direction: holding.predictedDirection),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
