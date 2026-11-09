import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../core/api_response.dart';
import '../../core/formatters.dart';
import '../../core/live_socket.dart';
import '../../models/dashboard.dart';
import '../../models/live_event.dart';
import '../../services/dashboard_service.dart';
import '../../widgets/common.dart';
import '../../widgets/live_widgets.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/state_views.dart';
import '../shared/live_alert_feed.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  StreamSubscription<LiveEvent>? _events;
  Timer? _reloadTimer;
  AdminDashboard? _dashboard;
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
      final AdminDashboard dashboard = await context.read<DashboardService>().admin();

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

  Future<void> _openInBrowser(String path) async {
    final Uri url = ApiConfig.webPage(path);
    final bool opened = await launchUrl(url, mode: LaunchMode.externalApplication);

    if (!opened && mounted) {
      showMessage(context, 'Could not open $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar('Admin dashboard'),
      body: StateSwitcher(
        loading: _loading,
        error: _error,
        hasData: _dashboard != null,
        onRetry: _retry,
        builder: (context) {
          final AdminDashboard dashboard = _dashboard!;

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
                      StatGrid(
                        children: [
                          StatCard(
                            title: 'Users',
                            icon: Icons.group_outlined,
                            value: CountText(dashboard.totalUsers),
                            subtitle: Text(
                              '${dashboard.investors} investors · ${dashboard.analysts} analysts · ${dashboard.admins} admins',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          StatCard(title: 'Portfolios', icon: Icons.folder_outlined, value: CountText(dashboard.portfolioCount)),
                          StatCard(title: 'Holdings', icon: Icons.show_chart, value: CountText(dashboard.holdingCount)),
                          StatCard(
                            title: 'Tickers tracked',
                            icon: Icons.candlestick_chart_outlined,
                            value: CountText(dashboard.tickersTracked),
                          ),
                        ],
                      ),
                      LiveAlertFeed(
                        emptyMessage: 'No risk label has changed since you opened the app.',
                        onOpenHolding: (holdingId) => context.push('/holdings/$holdingId'),
                      ),
                      const SectionTitle('Risk across all holdings'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: RiskDistributionBar(distribution: dashboard.riskDistribution),
                        ),
                      ),
                      const SectionTitle('Market data'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              InfoRow(label: 'Latest price date', value: Text(Formatters.date(dashboard.latestPriceDate))),
                              InfoRow(label: 'Last import', value: Text(Formatters.dateTime(dashboard.lastIngestedAt))),
                            ],
                          ),
                        ),
                      ),
                      const SectionTitle('Models in use'),
                      _ModelCard(title: 'Risk model', model: dashboard.riskModel),
                      const SizedBox(height: 8),
                      _ModelCard(title: 'Forecast model', model: dashboard.forecastModel),
                      const SectionTitle('Data and training'),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Dataset uploads and model training run in the Django web pages. Log in there with your admin account.',
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: () => _openInBrowser('/datasets/'),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open Datasets in browser'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => _openInBrowser('/ml/'),
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('Open ML Training in browser'),
                              ),
                            ],
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

class _ModelCard extends StatelessWidget {
  const _ModelCard({required this.title, required this.model});

  final String title;
  final ModelInfo? model;

  @override
  Widget build(BuildContext context) {
    final ModelInfo? info = model;
    final TextTheme text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (info == null)
              const Text('No trained model yet. Train one from the ML Training page.')
            else ...[
              InfoRow(label: 'Version', value: Text(info.version)),
              InfoRow(label: 'Algorithm', value: Text(info.algorithm ?? '-')),
              InfoRow(label: 'Trained at', value: Text(Formatters.dateTime(info.trainedAt))),
              InfoRow(label: 'Tickers', value: Text('${info.tickersCount}')),
              for (final MapEntry<String, double> metric in info.testMetrics.entries)
                InfoRow(
                  label: 'Test ${metric.key.replaceAll('_', ' ')}',
                  value: Text(metric.value.toStringAsFixed(3)),
                ),
              if (info.comparison != null) ...[
                const SizedBox(height: 8),
                Text(info.comparison!, style: text.bodySmall),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
