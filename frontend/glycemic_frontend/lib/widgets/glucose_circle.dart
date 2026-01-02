// lib/widgets/glucose_circle.dart

import 'package:flutter/material.dart';

class GlucoseCircle extends StatelessWidget {
  final int? value;

  const GlucoseCircle({super.key, this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: value != null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value!.toString(),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'mg/dL',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              )
            : const Text(
                '--',
                style: TextStyle(
                  fontSize: 32,
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }
}
