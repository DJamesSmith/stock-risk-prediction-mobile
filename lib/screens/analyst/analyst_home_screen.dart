import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_response.dart';
import '../../core/formatters.dart';
import '../../core/live_socket.dart';
import '../../models/dashboard.dart';
import '../../models/live_event.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/common.dart';
import '../../widgets/direction_badge.dart';
import '../../widgets/live_widgets.dart';
import '../../widgets/money_text.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/state_views.dart';
import '../shared/live_alert_feed.dart';

class AnalystHomeScreen extends StatefulWidget {
  const AnalystHomeScreen({super.key});

  @override
  State<AnalystHomeScreen> createState() => _AnalystHomeScreenState();
}

class _AnalystHomeScreenState extends State<AnalystHomeScreen> {
  StreamSubscription<LiveEvent>? _events;
  Timer? _reloadTimer;
  AnalystDashboard? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _events = context.read<LiveSocket>().events.listen(_onLiveEvent);
    _load();
  }

  @override
  void dispose() {
    _events?.cancel();
    _reloadTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final AnalystDashboard dashboard = await context.read<DashboardService>().analyst();

      if (mounted) {
        setState(() {
          _dashboard = dashboard;
          _error = null;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);

        if (_dashboard != null) {
          showMessage(context, error.message);
        }
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
      _reloadTimer?.cancel();
      _reloadTimer = Timer(const Duration(seconds: 1), _load);
    }
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
      appBar: buildAppBar('Analyst dashboard'),
      body: StateSwitcher(
        loading: _loading,
        error: _error,
        hasData: _dashboard != null,
        onRetry: _retry,
        builder: (context) {
          final AnalystDashboard dashboard = _dashboard!;

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                CenteredContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const LivePausedBar(),
                      LiveAlertFeed(
                        emptyMessage: 'No risk changes for your clients since you opened the app.',
                        onOpenHolding: (holdingId) => _open('/holdings/$holdingId'),
                      ),
                      const SizedBox(height: 12),
                      StatGrid(
                        children: [
                          StatCard(title: 'Clients', icon: Icons.people_outline, value: CountText(dashboard.clientCount)),
                          StatCard(title: 'Portfolios', icon: Icons.folder_outlined, value: CountText(dashboard.portfolioCount)),
                          StatCard(title: 'Holdings', icon: Icons.show_chart, value: CountText(dashboard.holdingCount)),
                          StatCard(
                            title: 'High risk',
                            icon: Icons.warning_amber_rounded,
                            value: CountText(dashboard.highRiskCount),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      StatCard(
                        title: 'Value under watch (daily close)',
                        icon: Icons.account_balance_wallet_outlined,
                        value: MoneyText(dashboard.totals.currentValue),
                        subtitle: MoneyText(
                          dashboard.totals.gainLoss,
                          signed: true,
                          percent: dashboard.totals.gainLossPercent,
                        ),
                      ),
                      const SectionTitle('Risk across clients'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: RiskDistributionBar(distribution: dashboard.riskDistribution),
                        ),
                      ),
                      SectionTitle('High-risk holdings (${dashboard.highRiskCount})'),
                      if (dashboard.highRiskHoldings.isEmpty)
                        const EmptyView(message: 'No holdings are labelled high risk.', icon: Icons.verified_outlined),
                      for (final HighRiskRow row in dashboard.highRiskHoldings)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: ListTile(
                              onTap: () => _open('/holdings/${row.holdingId}'),
                              title: Text(row.ticker, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(
                                '${row.investor?.username ?? '-'} · ${row.portfolioName}\n'
                                'Confidence ${Formatters.ratioPercent(row.riskScore)}',
                              ),
                              isThreeLine: true,
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  MoneyText(row.currentValue),
                                  const SizedBox(height: 4),
                                  DirectionBadge(direction: row.predictedDirection),
                                ],
                              ),
                            ),
                          ),
                        ),
                      SectionTitle('Clients (${dashboard.clientCount})'),
                      if (dashboard.clients.isEmpty)
                        const EmptyView(
                          message: 'No investors are assigned to you yet. An admin assigns clients from the Users screen.',
                          icon: Icons.person_search_outlined,
                        ),
                      for (final ClientRow client in dashboard.clients)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              client.username,
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                            ),
                                            Text(client.email, style: Theme.of(context).textTheme.bodySmall),
                                            Text(
                                              '${client.portfolioCount} portfolios · ${client.holdingCount} holdings',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          MoneyText(client.totals.currentValue),
                                          MoneyText(client.totals.gainLoss, signed: true),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  RiskDistributionBar(distribution: client.riskDistribution),
                                ],
                              ),
                            ),
                          ),
                        ),
                      const MlDisclaimer(),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
