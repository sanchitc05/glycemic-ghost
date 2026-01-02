import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/env_record.dart';

class GlucoseChart extends StatelessWidget {
  final List<EgvRecord> egvs;

  const GlucoseChart({super.key, required this.egvs});

  @override
  Widget build(BuildContext context) {
    if (egvs.isEmpty) {
      return const Center(child: Text('No CGM data for this period'));
    }

    final points = egvs.reversed.toList(); // oldest on left
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      spots.add(FlSpot(i.toDouble(), points[i].value.toDouble()));
    }

    final minVal = points
        .map((e) => e.value)
        .reduce((a, b) => a < b ? a : b)
        .toDouble();
    final maxVal = points
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    const padding = 20.0;
    final minY = (minVal - padding).clamp(40, 400).toDouble();
    final maxY = (maxVal + padding).clamp(40, 400).toDouble();
    final totalPoints = points.length.toDouble();

    final sampled = points; // for tooltip lookup

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 50,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: const Color.fromARGB(255, 95, 95, 95).withOpacity(0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 95, 95, 95)),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: (totalPoints / 4).clamp(1, totalPoints),
              getTitlesWidget: (value, meta) {
                final idx = value.round();
                if (idx < 0 || idx >= points.length) return Container();
                final egv = points[idx];
                final t = egv.displayTime;
                final timeStr =
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                return Text(
                  timeStr,
                  style: const TextStyle(fontSize: 10, color: Color.fromARGB(255, 95, 95, 95)),
                );
              },
            ),
          ),
        ),

        borderData: FlBorderData(show: false),

        lineTouchData: LineTouchData(
          enabled: true,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipMargin: 8,
            getTooltipColor: (spot) => Colors.white,
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              // ✅ FIXED: Check if empty first
              if (touchedSpots.isEmpty) return [];

              // ✅ FIXED: Get first spot safely
              final barSpot = touchedSpots.first;
              final index = barSpot.x.toInt();
              
              // ✅ FIXED: Bounds check
              if (index < 0 || index >= sampled.length) {
                return [];
              }

              final egv = sampled[index];
              final now = DateTime.now().toUtc();
              final t = egv.displayTime;
              final timeStr =
                  '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

              // ✅ FIXED: Manual loop instead of firstWhereOrNull
              EgvRecord? nearbyFood;
              for (final e in egvs) {
                // Check if this EGV is from FOOD event (add these fields to EgvRecord model)
                if (e.eventSource == 'FOOD' && 
                    (now.difference(e.systemTime.toUtc()).inMinutes.abs() < 30)) {
                  nearbyFood = e;
                  break;
                }
              }

              if (nearbyFood != null && nearbyFood.foodName != null) {
                // ✅ FIXED: FOOD event tooltip
                return [
                  LineTooltipItem(
                    '${egv.value} mg/dL\n',
                    const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: '$timeStr\n',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 11,
                        ),
                      ),
                      const TextSpan(
                        text: '🍎 FOOD: ',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      TextSpan(
                        text: nearbyFood.foodName!,
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ];
              }

              // ✅ FIXED: Default tooltip (no shadowing issues)
              return [
                LineTooltipItem(
                  '${egv.value} mg/dL\n',
                  const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: timeStr,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ];
            },
          ),
        ),

        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: const Color(0xFF2F4F60),
            barWidth: 2,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF2F4F60).withOpacity(0.08),
            ),
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
