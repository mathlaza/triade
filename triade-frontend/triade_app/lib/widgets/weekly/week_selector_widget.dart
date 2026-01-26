import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Premium Dark Theme Colors
const _kBorderColor = Color(0xFF38383A);
const _kGoldAccent = Color(0xFFFFD60A);
const _kTextPrimary = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF8E8E93);

/// Widget de seleção de semana com navegação
class WeekSelectorWidget extends StatelessWidget {
  final DateTime currentWeekStart;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onGoToCurrentWeek;
  final bool isCurrentWeek;

  const WeekSelectorWidget({
    super.key,
    required this.currentWeekStart,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onGoToCurrentWeek,
    required this.isCurrentWeek,
  });

  String _getWeekNumber() {
    final thursday = currentWeekStart.add(const Duration(days: 3));
    final year = thursday.year;
    final jan4 = DateTime(year, 1, 4);
    final firstThursday = jan4.subtract(Duration(days: (jan4.weekday - 4) % 7));
    final daysDiff = currentWeekStart.difference(firstThursday).inDays;
    final weekNumber = (daysDiff / 7).floor() + 1;
    return 'S$weekNumber de $year';
  }

  String _getWeekStatus() {
    final now = DateTime.now();
    final currentWeekStartOfToday = now.subtract(Duration(days: now.weekday - 1));
    final normalizedCurrentWeek = DateTime(currentWeekStartOfToday.year, currentWeekStartOfToday.month, currentWeekStartOfToday.day);
    final normalizedSelectedWeek = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);

    if (normalizedSelectedWeek.isAtSameMomentAs(normalizedCurrentWeek)) {
      return 'Atual';
    } else if (normalizedSelectedWeek.isBefore(normalizedCurrentWeek)) {
      return 'Passado';
    } else {
      return 'Futuro';
    }
  }

  @override
  Widget build(BuildContext context) {
    final weekEnd = currentWeekStart.add(const Duration(days: 6));
    final weekNumber = _getWeekNumber();
    final weekStatus = _getWeekStatus();

    Color statusColor;
    if (weekStatus == 'Atual') {
      statusColor = _kGoldAccent;
    } else if (weekStatus == 'Passado') {
      statusColor = _kTextSecondary;
    } else {
      statusColor = const Color(0xFFFF9F0A); // Laranja iOS
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF141416),
        border: Border(
          bottom: BorderSide(color: _kBorderColor, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Material(
            color: const Color(0xFF141416),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onPreviousWeek,
              borderRadius: BorderRadius.circular(20),
              splashColor: _kTextSecondary.withValues(alpha: 0.3),
              highlightColor: _kTextSecondary.withValues(alpha: 0.15),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.chevron_left, color: _kTextPrimary),
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  weekNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        weekStatus,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('dd/MM').format(currentWeekStart)} - ${DateFormat('dd/MM').format(weekEnd)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kTextSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isCurrentWeek)
            Material(
              color: const Color(0xFF141416),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onGoToCurrentWeek,
                borderRadius: BorderRadius.circular(20),
                splashColor: _kTextSecondary.withValues(alpha: 0.3),
                highlightColor: _kTextSecondary.withValues(alpha: 0.15),
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.today, color: _kGoldAccent),
                ),
              ),
            ),
          Material(
            color: const Color(0xFF141416),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: onNextWeek,
              borderRadius: BorderRadius.circular(20),
              splashColor: _kTextSecondary.withValues(alpha: 0.3),
              highlightColor: _kTextSecondary.withValues(alpha: 0.15),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.chevron_right, color: _kTextPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
