import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_response.dart';
import '../../core/formatters.dart';
import '../../core/live_socket.dart';
import '../../models/price.dart';
import '../../services/market_service.dart';
import '../../widgets/common.dart';
import '../../widgets/live_widgets.dart';
import '../../widgets/money_text.dart';
import '../../widgets/price_chart.dart';
import '../../widgets/state_views.dart';

class StockDetailScreen extends StatefulWidget {
  const StockDetailScreen({super.key, required this.ticker});

  final String ticker;

  @override
  State<StockDetailScreen> createState() => _StockDetailScreenState();
}

class _StockDetailScreenState extends State<StockDetailScreen> {
  static const int historyDays = 180;
  static const int tableRows = 10;

  late final LiveSocket _live;
  PriceRow? _latest;
  List<PriceRow> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _live = context.read<LiveSocket>();
    _live.follow([widget.ticker]);
    _load();
  }

  @override
  void dispose() {
    _live.unfollow([widget.ticker]);
    super.dispose();
  }

  Future<void> _load() async {
    final MarketService market = context.read<MarketService>();

    try {
      final PriceRow latest = await market.latestPrice(widget.ticker);
      final DateTime end = DateTime.tryParse(latest.date) ?? DateTime.now();
      final List<PriceRow> history = await market.history(
        widget.ticker,
        start: end.subtract(const Duration(days: historyDays)),
        end: end,
      );

      if (mounted) {
        setState(() {
          _latest = latest;
          _history = history;
          _error = null;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);

        if (_latest != null) {
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

  @override
  Widget build(BuildContext context) {
    final LiveSocket live = context.watch<LiveSocket>();
    final bool pinned = live.isPinned(widget.ticker);

    return Scaffold(
      appBar: buildAppBar(
        widget.ticker,
        actions: [
          TextButton.icon(
            onPressed: () => live.togglePin(widget.ticker),
            icon: Icon(pinned ? Icons.star : Icons.star_border),
            label: Text(pinned ? 'Following' : 'Follow'),
          ),
        ],
      ),
      body: StateSwitcher(
        loading: _loading,
        error: _error,
        hasData: _latest != null,
        onRetry: _retry,
        builder: (context) => _buildContent(context, live, _latest!),
      ),
    );
  }

  Widget _buildContent(BuildContext context, LiveSocket live, PriceRow latest) {
    final TextTheme text = Theme.of(context).textTheme;
    final List<ChartPoint> points = [];

    for (final PriceRow row in _history) {
      final DateTime? date = DateTime.tryParse(row.date);

      if (date != null) {
        points.add(ChartPoint(date: date, close: row.close));
      }
    }

    final List<PriceRow> recent = _history.reversed.take(tableRows).toList();

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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.ticker, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('Last daily close: ${Formatters.date(latest.date)}', style: text.bodySmall),
                              Text('Volume: ${Formatters.quantity(latest.volume.toDouble())}', style: text.bodySmall),
                            ],
                          ),
                        ),
                        LivePriceChip(quote: live.quoteFor(widget.ticker), fallbackPrice: latest.close, large: true),
                      ],
                    ),
                  ),
                ),
                const SectionTitle('Last 6 months'),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
                    child: PriceChart(points: points),
                  ),
                ),
                const SectionTitle('Recent daily prices'),
                Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Open'), numeric: true),
                        DataColumn(label: Text('High'), numeric: true),
                        DataColumn(label: Text('Low'), numeric: true),
                        DataColumn(label: Text('Close'), numeric: true),
                      ],
                      rows: [
                        for (final PriceRow row in recent)
                          DataRow(
                            cells: [
                              DataCell(Text(Formatters.date(row.date))),
                              DataCell(MoneyText(row.open)),
                              DataCell(MoneyText(row.high)),
                              DataCell(MoneyText(row.low)),
                              DataCell(MoneyText(row.close)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
