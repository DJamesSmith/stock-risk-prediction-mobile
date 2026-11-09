import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/live_socket.dart';
import '../../widgets/common.dart';
import '../../widgets/live_widgets.dart';
import '../../widgets/state_views.dart';

class StockLookupScreen extends StatefulWidget {
  const StockLookupScreen({super.key});

  @override
  State<StockLookupScreen> createState() => _StockLookupScreenState();
}

class _StockLookupScreenState extends State<StockLookupScreen> {
  static final RegExp tickerPattern = RegExp(r'^[A-Z][A-Z0-9.\-]{0,9}$');

  final TextEditingController _ticker = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _search() {
    final String ticker = _ticker.text.trim().toUpperCase();

    if (!tickerPattern.hasMatch(ticker)) {
      setState(() => _error = 'Enter a valid ticker symbol, for example AAPL or BRK.B.');
      return;
    }

    setState(() => _error = null);
    context.push('/stocks/$ticker');
  }

  @override
  Widget build(BuildContext context) {
    final LiveSocket live = context.watch<LiveSocket>();
    final List<String> pinned = live.pinnedTickers.toList()..sort();

    return Scaffold(
      appBar: buildAppBar('Stocks'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CenteredContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _ticker,
                  textCapitalization: TextCapitalization.characters,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    labelText: 'Look up a ticker',
                    hintText: 'AAPL',
                    prefixIcon: const Icon(Icons.search),
                    errorText: _error,
                    suffixIcon: IconButton(
                      tooltip: 'Search',
                      onPressed: _search,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ),
                ),
                const SectionTitle('Following'),
                const LivePausedBar(),
                if (pinned.isEmpty)
                  const EmptyView(
                    message: 'Open a stock and tap Follow to see its live price here.',
                    icon: Icons.star_border,
                  ),
                for (final String ticker in pinned)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/stocks/$ticker'),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Unfollow',
                                onPressed: () => live.togglePin(ticker),
                                icon: const Icon(Icons.star),
                              ),
                              Expanded(
                                child: Text(
                                  ticker,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              LivePriceChip(quote: live.quoteFor(ticker)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  'Live prices refresh about every 2 minutes during US market hours. Outside market hours you see the latest daily close.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
