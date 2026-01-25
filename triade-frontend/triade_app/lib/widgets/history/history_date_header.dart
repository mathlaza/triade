import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Cabeçalho de agrupamento por data no histórico
class HistoryDateHeader extends StatelessWidget {
  final DateTime date;
  final bool isFirst;

  const HistoryDateHeader({
    super.key,
    required this.date,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final taskDate = DateTime(date.year, date.month, date.day);

    String dayLabel;
    String dateLabel = DateFormat('dd/MM/yyyy', 'pt_BR').format(date);

    if (taskDate.isAtSameMomentAs(today)) {
      dayLabel = 'Hoje';
    } else if (taskDate.isAtSameMomentAs(yesterday)) {
      dayLabel = 'Ontem';
    } else if (taskDate.isAfter(today.subtract(const Duration(days: 7))) &&
        taskDate.isBefore(today)) {
      final weekday = DateFormat('EEEE', 'pt_BR').format(date);
      dayLabel = weekday[0].toUpperCase() + weekday.substring(1);
    } else if (taskDate.year == today.year) {
      dayLabel = DateFormat('d \'de\' MMMM', 'pt_BR').format(date);
      dateLabel = '';
    } else {
      dayLabel = DateFormat('MMMM yyyy', 'pt_BR').format(date);
      dateLabel = '';
    }

    return Container(
      margin: EdgeInsets.only(
        top: isFirst ? 8 : 14,
        bottom: 5,
        left: 16,
        right: 16,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFA500),
          ],
        ),
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today,
            size: 14,
            color: Color(0xFF1A1A2E),
          ),
          const SizedBox(width: 8),
          Text(
            dayLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A2E),
              letterSpacing: 0.4,
            ),
          ),
          if (dateLabel.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              '• $dateLabel',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF16213E),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
