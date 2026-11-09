import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/risk.dart';
import 'live_widgets.dart';

PreferredSizeWidget buildAppBar(String title, {List<Widget> actions = const []}) {
  return AppBar(
    title: Text(title),
    actions: [...actions, const ConnectionIndicator()],
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow({super.key, required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
  }
}

class MlDisclaimer extends StatelessWidget {
  const MlDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: colors.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Risk labels and forecasts come from machine-learning models. They are not financial advice.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class RiskDistributionBar extends StatelessWidget {
  const RiskDistributionBar({super.key, required this.distribution});

  final RiskDistribution distribution;

  @override
  Widget build(BuildContext context) {
    final List<_Segment> segments = [
      _Segment('Low', distribution.low, AppColors.low),
      _Segment('Medium', distribution.medium, AppColors.medium),
      _Segment('High', distribution.high, AppColors.high),
      _Segment('Not rated', distribution.notRated, AppColors.notRated),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 12,
            child: distribution.total == 0
                ? Container(color: Theme.of(context).colorScheme.surfaceContainerHighest)
                : Row(
                    children: [
                      for (final _Segment segment in segments)
                        if (segment.count > 0)
                          Expanded(flex: segment.count, child: Container(color: segment.color)),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            for (final _Segment segment in segments)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: segment.color, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text('${segment.label}: ${segment.count}'),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

class _Segment {
  _Segment(this.label, this.count, this.color);

  final String label;
  final int count;
  final Color color;
}

class CenteredContent extends StatelessWidget {
  const CenteredContent({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: child,
      ),
    );
  }
}
