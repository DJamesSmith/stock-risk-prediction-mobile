import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../core/formatters.dart';

class RiskBadge extends StatelessWidget {
  const RiskBadge({super.key, required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final String text = label == null ? 'Not rated' : '${Formatters.title(label)} risk';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.riskColor(label),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.riskTextColor(label),
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
