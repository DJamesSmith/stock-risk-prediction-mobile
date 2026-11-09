import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../core/formatters.dart';
import '../models/price.dart';

class PriceChart extends StatelessWidget {
  const PriceChart({super.key, required this.points, this.buyPrice});

  final List<ChartPoint> points;
  final double? buyPrice;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextStyle? labelStyle = Theme.of(context).textTheme.labelSmall;

    if (points.length < 2) {
      return SizedBox(
        height: 120,
        child: Center(child: Text('Not enough price data for a chart.', style: labelStyle)),
      );
    }

    final List<FlSpot> spots = [];

    for (int index = 0; index < points.length; index++) {
      spots.add(FlSpot(index.toDouble(), points[index].close));
    }

    double lowest = points.map((point) => point.close).reduce(min);
    double highest = points.map((point) => point.close).reduce(max);
    final double? buy = buyPrice;

    if (buy != null) {
      lowest = min(lowest, buy);
      highest = max(highest, buy);
    }

    final double padding = max((highest - lowest) * 0.08, 1.0);
    final bool rising = points.last.close >= points.first.close;
    final Color lineColor = rising ? AppColors.up : AppColors.down;
    final double labelStep = max(1.0, (points.length / 4).floorToDouble());

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minY: lowest - padding,
          maxY: highest + padding,
          gridData: FlGridData(
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: colors.outlineVariant, strokeWidth: 0.5),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }

                  return Text(value.toStringAsFixed(0), style: labelStyle);
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: labelStep,
                getTitlesWidget: (value, meta) {
                  final int index = value.round();

                  if (index < 0 || index >= points.length || value != index.toDouble()) {
                    return const SizedBox.shrink();
                  }

                  final DateTime date = points[index].date;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text('${date.day}/${date.month}', style: labelStyle),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              if (buy != null)
                HorizontalLine(
                  y: buy,
                  color: colors.primary,
                  strokeWidth: 1.5,
                  dashArray: [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    style: labelStyle?.copyWith(color: colors.primary, fontWeight: FontWeight.w600),
                    labelResolver: (line) => 'Buy ${Formatters.money(line.y)}',
                  ),
                ),
            ],
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) => colors.inverseSurface,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final ChartPoint point = points[spot.x.round()];
                  return LineTooltipItem(
                    '${Formatters.date(point.date.toIso8601String())}\n${Formatters.money(point.close)}',
                    TextStyle(color: colors.onInverseSurface, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: false,
              color: lineColor,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: lineColor.withValues(alpha: 0.12)),
            ),
          ],
        ),
      ),
    );
  }
}
