import 'package:flutter/material.dart';
import 'package:triade_app/models/dashboard_stats.dart';

/// Card de insight baseado na distribuição de energia
class DashboardInsightCard extends StatelessWidget {
  final Insight insight;

  const DashboardInsightCard({
    super.key,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    final color = _parseHexColor(insight.colorHex);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(color),
          const SizedBox(height: 16),
          _buildMessage(),
        ],
      ),
    );
  }

  Widget _buildHeader(Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Icon(_getInsightIcon(), color: color, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'INSIGHT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF8E8E93),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                insight.title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessage() {
    return Text(
      insight.message,
      style: const TextStyle(
        fontSize: 14,
        height: 1.5,
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  IconData _getInsightIcon() {
    switch (insight.type) {
      case 'BURNOUT':
        return Icons.local_fire_department_rounded;
      case 'LAZY':
        return Icons.bedtime_rounded;
      case 'BALANCED':
        return Icons.check_circle_rounded;
      case 'HIGH_PERFORMER':
        return Icons.emoji_events_rounded;
      case 'NEGLECTING_RENEWAL':
        return Icons.battery_alert_rounded;
      default:
        return Icons.psychology_rounded;
    }
  }

  Color _parseHexColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }
}
