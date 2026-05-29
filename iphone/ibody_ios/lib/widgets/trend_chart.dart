import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/vital_reading.dart';
import '../theme/app_colors.dart';

class TrendChart extends StatelessWidget {
  final List<VitalReading> readings;
  final Color color;
  final double height;
  final bool showDots;

  const TrendChart({
    super.key,
    required this.readings,
    required this.color,
    this.height = 120,
    this.showDots = false,
  });

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text('No data yet', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        ),
      );
    }

    final sorted = List<VitalReading>.from(readings)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final spots = sorted.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.value)).toList();
    final values = sorted.map((r) => r.value).toList();
    final minY = (values.reduce((a, b) => a < b ? a : b) * 0.95).floorToDouble();
    final maxY = (values.reduce((a, b) => a > b ? a : b) * 1.05).ceilToDouble();

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: (maxY - minY) / 3,
            getDrawingHorizontalLine: (v) => FlLine(
              color: AppColors.dividerLight.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: AppColors.textTertiary),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: color,
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: showDots,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3,
                  color: color,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.navy.withValues(alpha: 0.9),
              tooltipRoundedRadius: 10,
              getTooltipItems: (spots) => spots.map((s) {
                final r = sorted[s.spotIndex];
                return LineTooltipItem(
                  '${r.formattedValue} ${r.type.unit}',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
