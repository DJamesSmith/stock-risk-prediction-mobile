import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.title, required this.value, this.subtitle, this.icon});

  final String title;
  final Widget value;
  final Widget? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: colors.primary),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: Text(title, style: text.labelLarge?.copyWith(color: colors.onSurfaceVariant)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            DefaultTextStyle.merge(
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              child: value,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              subtitle!,
            ],
          ],
        ),
      ),
    );
  }
}

class StatGrid extends StatelessWidget {
  const StatGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth > 700 ? 4 : 2;
        final double width = (constraints.maxWidth - (columns - 1) * 12) / columns;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children.map((child) => SizedBox(width: width, child: child)).toList(),
        );
      },
    );
  }
}

class CountText extends StatelessWidget {
  const CountText(this.value, {super.key});

  final int value;

  @override
  Widget build(BuildContext context) {
    return Text('$value');
  }
}
