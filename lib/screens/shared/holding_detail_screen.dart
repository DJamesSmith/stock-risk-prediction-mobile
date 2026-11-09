import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/api_response.dart';
import '../../core/formatters.dart';
import '../../core/live_socket.dart';
import '../../models/forecast.dart';
import '../../models/holding.dart';
import '../../models/live_event.dart';
import '../../models/live_quote.dart';
import '../../models/price.dart';
import '../../models/risk.dart';
import '../../models/user.dart';
import '../../services/analytics_service.dart';
import '../../services/dashboard_service.dart';
import '../../services/holding_service.dart';
import '../../services/market_service.dart';
import '../../state/session.dart';
import '../../widgets/common.dart';
import '../../widgets/direction_badge.dart';
import '../../widgets/live_widgets.dart';
import '../../widgets/money_text.dart';
import '../../widgets/price_chart.dart';
import '../../widgets/risk_badge.dart';
import '../../widgets/state_views.dart';

class HoldingDetailScreen extends StatefulWidget {
  const HoldingDetailScreen({super.key, required this.holdingId});

  final int holdingId;

  @override
  State<HoldingDetailScreen> createState() => _HoldingDetailScreenState();
}

class _HoldingDetailScreenState extends State<HoldingDetailScreen> {
  static const Duration liveEventWait = Duration(seconds: 30);
  static const Duration pollInterval = Duration(seconds: 3);
  static const int maxPolls = 20;
  static const List<int> chartRanges = [30, 90, 180, 365];

  late final LiveSocket _live;
  StreamSubscription<LiveEvent>? _events;
  String? _followedTicker;
  Holding? _holding;
  HoldingRisk? _risk;
  HoldingForecast? _forecast;
  HoldingTrend? _trend;
  int _rangeDays = 180;
  bool _loading = true;
  bool _chartLoading = false;
  bool _recomputing = false;
  bool _refreshing = false;
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
    final String? ticker = _followedTicker;

    if (ticker != null) {
      _live.unfollow([ticker]);
    }

    super.dispose();
  }

  Future<void> _load() async {
    try {
      final List<Object> results = await Future.wait<Object>([
        context.read<HoldingService>().detail(widget.holdingId),
        context.read<AnalyticsService>().holdingRisk(widget.holdingId),
        context.read<AnalyticsService>().holdingForecast(widget.holdingId),
        context.read<DashboardService>().holdingTrend(widget.holdingId),
      ]);

      if (!mounted) {
        return;
      }

      final Holding holding = results[0] as Holding;

      if (_followedTicker == null) {
        _followedTicker = holding.ticker;
        _live.follow([holding.ticker]);
      }

      setState(() {
        _holding = holding;
        _risk = results[1] as HoldingRisk;
        _forecast = results[2] as HoldingForecast;
        _trend = results[3] as HoldingTrend;
        _rangeDays = 180;
        _error = null;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _error = error.message);

      if (_holding != null) {
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

  Future<void> _reloadPredictions() async {
    try {
      final List<Object> results = await Future.wait<Object>([
        context.read<HoldingService>().detail(widget.holdingId),
        context.read<AnalyticsService>().holdingRisk(widget.holdingId),
        context.read<AnalyticsService>().holdingForecast(widget.holdingId),
      ]);

      if (mounted) {
        setState(() {
          _holding = results[0] as Holding;
          _risk = results[1] as HoldingRisk;
          _forecast = results[2] as HoldingForecast;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        showMessage(context, error.message);
      }
    }
  }

  void _onLiveEvent(LiveEvent event) {
    if (event.isHoldingEvent && event.holdingId == widget.holdingId && !_recomputing) {
      _reloadPredictions();
    }
  }

  Future<void> _changeRange(int days) async {
    final HoldingTrend? trend = _trend;

    if (trend == null || days == _rangeDays) {
      return;
    }

    final DateTime end = DateTime.tryParse(trend.end) ?? DateTime.now();
    final DashboardService service = context.read<DashboardService>();

    setState(() {
      _rangeDays = days;
      _chartLoading = true;
    });

    try {
      final HoldingTrend updated = await service.holdingTrend(
        widget.holdingId,
        start: end.subtract(Duration(days: days)),
        end: end,
      );

      if (mounted) {
        setState(() => _trend = updated);
      }
    } on ApiException catch (error) {
      if (mounted) {
        showMessage(context, error.message);
      }
    }

    if (mounted) {
      setState(() => _chartLoading = false);
    }
  }

  Future<void> _recompute() async {
    final AnalyticsService analytics = context.read<AnalyticsService>();
    final Completer<void> finished = Completer<void>();
    final Set<String> seenTaskIds = {};
    String? taskId;

    setState(() => _recomputing = true);

    final StreamSubscription<LiveEvent> subscription = _live.events.listen((event) {
      final String? eventTaskId = event.taskId;

      if (event.type != 'prediction.updated' || eventTaskId == null) {
        return;
      }

      if (taskId == null) {
        seenTaskIds.add(eventTaskId);
      } else if (eventTaskId == taskId && !finished.isCompleted) {
        finished.complete();
      }
    });

    String message;

    try {
      final String queuedTaskId = await analytics.recompute(widget.holdingId);
      taskId = queuedTaskId;

      if (seenTaskIds.contains(queuedTaskId) && !finished.isCompleted) {
        finished.complete();
      }

      try {
        await finished.future.timeout(liveEventWait);
        message = 'Prediction updated live.';
      } on TimeoutException {
        message = await _pollTask(analytics, queuedTaskId);
      }

      await _reloadPredictions();
    } on ApiException catch (error) {
      message = error.message;
    }

    await subscription.cancel();

    if (mounted) {
      setState(() => _recomputing = false);
      showMessage(context, message);
    }
  }

  Future<String> _pollTask(AnalyticsService analytics, String taskId) async {
    for (int attempt = 0; attempt < maxPolls; attempt++) {
      final TaskStatus status = await analytics.taskStatus(taskId);

      if (status.ready) {
        if (status.succeeded) {
          return 'Prediction updated (checked by polling).';
        }

        return 'Recompute failed: ${status.error ?? status.state}.';
      }

      await Future<void>.delayed(pollInterval);
    }

    return 'Recompute is still running. Pull down to refresh later.';
  }

  Future<void> _refreshPrices() async {
    final Holding? holding = _holding;

    if (holding == null) {
      return;
    }

    setState(() => _refreshing = true);

    try {
      final String message = await context.read<MarketService>().refresh(holding.ticker);

      if (mounted) {
        showMessage(context, '$message New prices arrive live when the download finishes.');
      }
    } on ApiException catch (error) {
      if (mounted) {
        showMessage(context, error.message);
      }
    }

    if (mounted) {
      setState(() => _refreshing = false);
    }
  }

  Future<void> _edit() async {
    await context.push('/holdings/${widget.holdingId}/edit');

    if (mounted) {
      _load();
    }
  }

  Future<void> _delete() async {
    final Holding? holding = _holding;

    if (holding == null) {
      return;
    }

    final bool confirmed = await confirmAction(
      context,
      title: 'Delete ${holding.ticker}?',
      message: 'This holding will be removed from the portfolio. This cannot be undone.',
    );

    if (!confirmed || !mounted) {
      return;
    }

    try {
      await context.read<HoldingService>().remove(holding.id);

      if (mounted) {
        showMessage(context, 'Holding deleted.');
        context.pop(true);
      }
    } on ApiException catch (error) {
      if (mounted) {
        showMessage(context, error.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? user = context.select<Session, AppUser?>((session) => session.user);
    final bool canModify = user != null && !user.isAnalyst && _holding != null;
    final bool canRunActions = user != null && !user.isInvestor;

    return Scaffold(
      appBar: buildAppBar(
        _holding?.ticker ?? 'Holding',
        actions: [
          if (canModify)
            IconButton(tooltip: 'Edit holding', onPressed: _edit, icon: const Icon(Icons.edit_outlined)),
          if (canModify)
            IconButton(tooltip: 'Delete holding', onPressed: _delete, icon: const Icon(Icons.delete_outline)),
        ],
      ),
      body: StateSwitcher(
        loading: _loading,
        error: _error,
        hasData: _holding != null && _risk != null && _forecast != null && _trend != null,
        onRetry: _retry,
        builder: (context) {
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
                      _buildPosition(context),
                      if (canRunActions) ...[
                        const SectionTitle('Analyst actions'),
                        _buildActions(),
                      ],
                      const SectionTitle('Risk'),
                      _buildRisk(context, _risk!),
                      const SectionTitle('Next trading day'),
                      _buildForecast(context, _forecast!),
                      SectionTitle('Price trend', trailing: _chartLoading ? const _SmallSpinner() : null),
                      _buildChart(context, _trend!),
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

  Widget _buildPosition(BuildContext context) {
    final Holding holding = _holding!;
    final TextTheme text = Theme.of(context).textTheme;

    return Selector<LiveSocket, LiveQuote?>(
      selector: (context, live) => live.quoteFor(holding.ticker),
      builder: (context, quote, child) {
        final double price = quote?.price ?? holding.currentPrice ?? holding.buyPrice;
        final double value = holding.quantity * price;
        final double gainLoss = value - holding.cost;
        final double percent = holding.cost == 0 ? 0 : gainLoss / holding.cost * 100;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                          Text(holding.ticker, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
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
                    LivePriceChip(quote: quote, fallbackPrice: holding.currentPrice, large: true),
                  ],
                ),
                const Divider(height: 24),
                InfoRow(label: 'Quantity', value: Text(Formatters.quantity(holding.quantity))),
                InfoRow(label: 'Buy price', value: MoneyText(holding.buyPrice)),
                InfoRow(label: 'Buy date', value: Text(Formatters.date(holding.buyDate))),
                InfoRow(label: 'Cost', value: MoneyText(holding.cost)),
                InfoRow(label: 'Current value', value: MoneyText(value)),
                InfoRow(label: 'Gain / loss', value: MoneyText(gainLoss, signed: true, percent: percent)),
                if (quote != null)
                  InfoRow(
                    label: 'Price as of',
                    value: Text(quote.isLive ? Formatters.dateTime(quote.asOf) : Formatters.date(quote.date)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton.icon(
              onPressed: _recomputing ? null : _recompute,
              icon: _recomputing ? const _SmallSpinner() : const Icon(Icons.psychology_outlined),
              label: Text(_recomputing ? 'Waiting for the new prediction...' : 'Recompute prediction'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _refreshing ? null : _refreshPrices,
              icon: _refreshing ? const _SmallSpinner() : const Icon(Icons.sync),
              label: const Text('Refresh prices'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRisk(BuildContext context, HoldingRisk risk) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InfoRow(label: 'Risk label', value: RiskBadge(label: risk.riskLabel)),
            InfoRow(label: 'Confidence', value: Text(Formatters.ratioPercent(risk.riskScore))),
            InfoRow(label: 'Model version', value: Text(risk.modelVersion.isEmpty ? '-' : risk.modelVersion)),
            InfoRow(label: 'Last predicted', value: Text(Formatters.dateTime(risk.lastPredictedAt))),
            InfoRow(label: 'Holding age', value: Text('${risk.holdingAgeDays} days')),
            InfoRow(
              label: 'Unrealised gain / loss',
              value: Text(Formatters.signedPercent(risk.unrealisedGainLossPercent)),
            ),
            if (risk.riskLabel == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('No risk prediction yet. Predictions run every night, or an analyst can recompute now.'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecast(BuildContext context, HoldingForecast forecast) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InfoRow(label: 'Direction', value: DirectionBadge(direction: forecast.predictedDirection)),
            InfoRow(label: 'Confidence', value: Text(Formatters.ratioPercent(forecast.predictionConfidence))),
            InfoRow(
              label: 'Model version',
              value: Text(forecast.modelVersion.isEmpty ? '-' : forecast.modelVersion),
            ),
            InfoRow(label: 'Last predicted', value: Text(Formatters.dateTime(forecast.lastPredictedAt))),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context, HoldingTrend trend) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final int days in chartRanges)
                  ChoiceChip(
                    label: Text(_rangeLabel(days)),
                    selected: _rangeDays == days,
                    onSelected: _chartLoading ? null : (_) => _changeRange(days),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            PriceChart(points: trend.points, buyPrice: trend.buyPrice),
            const SizedBox(height: 8),
            Text(
              '${Formatters.date(trend.start)} to ${Formatters.date(trend.end)} · dashed line is the buy price',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _rangeLabel(int days) {
    if (days == 30) {
      return '1M';
    }

    if (days == 90) {
      return '3M';
    }

    if (days == 180) {
      return '6M';
    }

    return '1Y';
  }
}

class _SmallSpinner extends StatelessWidget {
  const _SmallSpinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
  }
}
