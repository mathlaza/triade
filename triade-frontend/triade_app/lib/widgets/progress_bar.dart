import 'package:flutter/material.dart';

class DailyProgressBar extends StatelessWidget {
  final double usedHours;
  final double availableHours;

  const DailyProgressBar({
    super.key,
    required this.usedHours,
    required this.availableHours,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = availableHours > 0 ? usedHours / availableHours : 0.0;
    final isOverloaded = usedHours > availableHours;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Capacidade do Dia',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${usedHours.toStringAsFixed(1)}h / ${availableHours.toStringAsFixed(1)}h',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isOverloaded ? Colors.red : Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverloaded ? Colors.red : Colors.green,
              ),
            ),
          ),
          if (isOverloaded) ...[
            const SizedBox(height: 8),
            const Text(
              '⚠️ Dia estourado! Libere espaço.',
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
