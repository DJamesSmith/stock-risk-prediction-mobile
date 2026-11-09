import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../core/formatters.dart';
import '../core/live_socket.dart';
import '../models/live_event.dart';
import '../models/live_quote.dart';
import 'risk_badge.dart';

class ConnectionIndicator extends StatelessWidget {
  const ConnectionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final LiveStatus status = context.select<LiveSocket, LiveStatus>((live) => live.status);
    Color color = AppColors.offline;
    String label = 'Offline';

    if (status == LiveStatus.connected) {
      color = AppColors.live;
      label = 'Live';
    } else if (status == LiveStatus.connecting || status == LiveStatus.reconnecting) {
      color = AppColors.reconnecting;
      label = 'Reconnecting';
    }

    return Tooltip(
      message: 'Live updates: $label',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class LivePausedBar extends StatelessWidget {
  const LivePausedBar({super.key});

  @override
  Widget build(BuildContext context) {
    final LiveStatus status = context.select<LiveSocket, LiveStatus>((live) => live.status);

    if (status == LiveStatus.connected) {
      return const SizedBox.shrink();
    }

    final ColorScheme colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          const Expanded(child: Text('Live updates paused. Showing the last loaded data.')),
        ],
      ),
    );
  }
}

class LivePriceChip extends StatefulWidget {
  const LivePriceChip({super.key, required this.quote, this.fallbackPrice, this.large = false});

  final LiveQuote? quote;
  final double? fallbackPrice;
  final bool large;

  @override
  State<LivePriceChip> createState() => _LivePriceChipState();
}

class _LivePriceChipState extends State<LivePriceChip> {
  bool _flash = false;
  Timer? _timer;

  @override
  void didUpdateWidget(LivePriceChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final double? before = oldWidget.quote?.price;
    final double? after = widget.quote?.price;

    if (before != null && after != null && before != after) {
      _timer?.cancel();
      setState(() => _flash = true);
      _timer = Timer(const Duration(milliseconds: 900), () {
        if (mounted) {
          setState(() => _flash = false);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final LiveQuote? quote = widget.quote;
    final double? price = quote?.price ?? widget.fallbackPrice;
    final String sourceLabel = quote?.sourceLabel ?? 'Daily close';
    final Color changeColor = AppColors.gainColor(quote?.change);
    final TextStyle? priceStyle = widget.large ? text.headlineMedium : text.titleMedium;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _flash ? colors.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(Formatters.money(price), style: priceStyle?.copyWith(fontWeight: FontWeight.w600)),
          if (quote != null)
            Text(
              '${Formatters.signedMoney(quote.change)} (${Formatters.signedPercent(quote.changePercent)})',
              style: text.labelMedium?.copyWith(color: changeColor),
            ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                quote != null && quote.isLive ? Icons.sensors : Icons.event,
                size: 12,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(sourceLabel, style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class RiskAlertBanner extends StatelessWidget {
  const RiskAlertBanner({super.key, required this.alert, this.onTap, this.onDismiss, this.showOwner = false});

  final RiskAlert alert;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;
  final bool showOwner;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color background = alert.isWorse ? colors.errorContainer : colors.secondaryContainer;
    final Color foreground = alert.isWorse ? colors.onErrorContainer : colors.onSecondaryContainer;
    String details = '${alert.portfolioName} · ${Formatters.time(alert.receivedAt)}';

    if (showOwner) {
      details = '${alert.owner} · $details';
    }

    return Card(
      color: background,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            children: [
              Icon(alert.isWorse ? Icons.warning_amber_rounded : Icons.info_outline, color: foreground),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.headline,
                      style: text.titleSmall?.copyWith(color: foreground, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(details, style: text.bodySmall?.copyWith(color: foreground)),
                  ],
                ),
              ),
              RiskBadge(label: alert.riskLabel),
              if (onDismiss != null)
                IconButton(
                  tooltip: 'Dismiss',
                  onPressed: onDismiss,
                  icon: Icon(Icons.close, color: foreground),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
