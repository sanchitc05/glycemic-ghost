// lib/widgets/fitness_summary_row.dart
import 'package:flutter/material.dart';

class FitnessSummaryRow extends StatelessWidget {
  final int steps;
  final int calories;
  final int avgHeartRate;
  final double? bmi;

  const FitnessSummaryRow({
    super.key,
    required this.steps,
    required this.calories,
    required this.avgHeartRate,
    this.bmi,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _item('Steps', steps.toString()),
          _item('Calories', calories.toString()),
          _item('Avg HR', '$avgHeartRate bpm'),
          _item('BMI', bmi?.toStringAsFixed(1) ?? '--'),
        ],
      ),
    );
  }

  Widget _item(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
