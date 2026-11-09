import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/live_socket.dart';
import '../../models/live_event.dart';
import '../../widgets/common.dart';
import '../../widgets/live_widgets.dart';

class LiveAlertFeed extends StatelessWidget {
  const LiveAlertFeed({super.key, required this.emptyMessage, required this.onOpenHolding, this.maxItems = 10});

  final String emptyMessage;
  final void Function(int holdingId) onOpenHolding;
  final int maxItems;

  @override
  Widget build(BuildContext context) {
    final LiveSocket live = context.watch<LiveSocket>();
    final List<RiskAlert> alerts = live.alerts.take(maxItems).toList();
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          'Live risk alerts (${live.alerts.length})',
          trailing: live.alerts.isEmpty
              ? null
              : TextButton(onPressed: live.clearAlerts, child: const Text('Clear')),
        ),
        if (alerts.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.notifications_none, color: colors.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(child: Text(emptyMessage)),
              ],
            ),
          ),
        for (final RiskAlert alert in alerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: RiskAlertBanner(
              alert: alert,
              showOwner: true,
              onTap: () => onOpenHolding(alert.holdingId),
              onDismiss: () => live.dismissAlert(alert),
            ),
          ),
      ],
    );
  }
}
