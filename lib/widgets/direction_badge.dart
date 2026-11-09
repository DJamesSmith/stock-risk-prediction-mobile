import 'package:flutter/material.dart';

import '../config/theme.dart';

class DirectionBadge extends StatelessWidget {
  const DirectionBadge({super.key, required this.direction});

  final String? direction;

  @override
  Widget build(BuildContext context) {
    IconData icon = Icons.remove;
    Color color = AppColors.notRated;
    String text = 'No forecast';

    if (direction == 'up') {
      icon = Icons.arrow_upward;
      color = AppColors.up;
      text = 'Up';
    } else if (direction == 'down') {
      icon = Icons.arrow_downward;
      color = AppColors.down;
      text = 'Down';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
