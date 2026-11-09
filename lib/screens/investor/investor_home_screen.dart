import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_response.dart';
import '../../core/formatters.dart';
import '../../core/live_socket.dart';
import '../../models/dashboard.dart';
import '../../models/live_event.dart';
import '../../models/live_quote.dart';
import '../../models/portfolio.dart';
import '../../services/dashboard_service.dart';
import '../../services/portfolio_service.dart';
import '../../widgets/common.dart';
import '../../widgets/live_widgets.dart';
import '../../widgets/money_text.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/state_views.dart';

class InvestorHomeScreen extends StatefulWidget {
  const InvestorHomeScreen({super.key});

  @override
  State<InvestorHomeScreen> createState() => _InvestorHomeScreenState();
}

class _InvestorHomeScreenState extends State<InvestorHomeScreen> {
  late final LiveSocket _live;
  StreamSubscription<LiveEvent>? _events;
  Timer? _reloadTimer;
  Set<String> _followed = {};
  InvestorDashboard? _dashboard;
  Map<int, PortfolioSummary> _summaries = {};
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
    final DashboardService dashboards = context.read<DashboardService>();
    final PortfolioService portfolios = context.read<PortfolioService>();

    try {
      final InvestorDashboard dashboard = await dashboards.investor();
      final List<PortfolioSummary> summaries = await Future.wait(
        dashboard.portfolios.map((row) => portfolios.summary(row.id)),
      );

      if (!mounted) {
        return;
      }

      final Set<String> tickers = {};
      final Map<int, PortfolioSummary> byId = {};

      for (final PortfolioSummary summary in summaries) {
        byId[summary.portfolioId] = summary;
        tickers.addAll(summary.holdings.map((holding) => holding.ticker));
      }

      _live.follow(tickers.difference(_followed));
      _live.unfollow(_followed.difference(tickers));
      _followed = tickers;

      setState(() {
        _dashboard = dashboard;
        _summaries = byId;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _error = error.message);

      if (_dashboard != null) {
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

  void _onLiveEvent(LiveEvent event) {
    if (event.type == 'risk.changed') {
      _scheduleReload();
    }
  }

  void _scheduleReload() {
    _reloadTimer?.cancel();
    _reloadTimer = Timer(const Duration(seconds: 1), _load);
  }

  double _liveValue(PortfolioSummary summary, LiveSocket live) {
    double total = 0;

    for (final HoldingPosition position in summary.holdings) {
      final LiveQuote? quote = live.quoteFor(position.ticker);
      final double price = quote?.price ?? position.currentPrice ?? position.buyPrice;
      total += position.quantity * price;
    }

    return total;
  }

  Future<void> _open(String path) async {
    await context.push(path);

    if (mounted) {
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('My dashboard'),
      body: StateSwitcher(
        loading: _loading,
        error: _error,
        hasData: _dashboard != null,
        onRetry: _retry,
        builder: (context) {
          return RefreshIndicator(
            onRefresh: _load,
            child: Consumer<LiveSocket>(
              builder: (context, live, child) => _buildContent(context, live, _dashboard!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, LiveSocket live, InvestorDashboard dashboard) {
    final TextTheme text = Theme.of(context).textTheme;
    double totalValue = 0;
    bool hasLive = false;

    for (final PortfolioRow row in dashboard.portfolios) {
      final PortfolioSummary? summary = _summaries[row.id];
      totalValue += summary == null ? row.totals.currentValue : _liveValue(summary, live);
    }

    for (final String ticker in _followed) {
      hasLive = hasLive || (live.quoteFor(ticker)?.isLive ?? false);
    }

    final double gainLoss = totalValue - dashboard.totals.totalCost;
    final double gainLossPercent = dashboard.totals.totalCost == 0 ? 0 : gainLoss / dashboard.totals.totalCost * 100;
    final RiskAlert? latestAlert = live.alerts.isEmpty ? null : live.alerts.first;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        CenteredContent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LivePausedBar(),
              if (latestAlert != null) ...[
                RiskAlertBanner(
                  alert: latestAlert,
                  onTap: () => _open('/holdings/${latestAlert.holdingId}'),
                  onDismiss: () => live.dismissAlert(latestAlert),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('Total value', style: text.labelLarge)),
                          Chip(
                            avatar: Icon(hasLive ? Icons.sensors : Icons.event, size: 16),
                            label: Text(hasLive ? 'Live' : 'Daily close'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      MoneyText(totalValue, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      MoneyText(gainLoss, signed: true, percent: gainLossPercent, style: text.titleSmall),
                      Text('Total cost ${Formatters.money(dashboard.totals.totalCost)}', style: text.bodySmall),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StatGrid(
                children: [
                  StatCard(
                    title: 'Portfolios',
                    icon: Icons.folder_outlined,
                    value: CountText(dashboard.portfolioCount),
                  ),
                  StatCard(
                    title: 'Holdings',
                    icon: Icons.show_chart,
                    value: CountText(dashboard.holdingCount),
                  ),
                ],
              ),
              const SectionTitle('Risk across holdings'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: RiskDistributionBar(distribution: dashboard.riskDistribution),
                ),
              ),
              const SectionTitle('Portfolios'),
              if (dashboard.portfolios.isEmpty)
                const EmptyView(
                  message: 'No portfolios yet. Open the Portfolios tab to create your first one.',
                  icon: Icons.folder_open,
                ),
              for (final PortfolioRow row in dashboard.portfolios)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      onTap: () => _open('/portfolios/${row.id}'),
                      title: Text(row.name),
                      subtitle: Text('${row.holdingsCount} holdings'),
                      trailing: _PortfolioValue(
                        value: _summaries[row.id] == null
                            ? row.totals.currentValue
                            : _liveValue(_summaries[row.id]!, live),
                        cost: row.totals.totalCost,
                      ),
                    ),
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

class _PortfolioValue extends StatelessWidget {
  const _PortfolioValue({required this.value, required this.cost});

  final double value;
  final double cost;

  @override
  Widget build(BuildContext context) {
    final double gainLoss = value - cost;
    final double percent = cost == 0 ? 0 : gainLoss / cost * 100;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        MoneyText(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        MoneyText(gainLoss, signed: true, percent: percent, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
