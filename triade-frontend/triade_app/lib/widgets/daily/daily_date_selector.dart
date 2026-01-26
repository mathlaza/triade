import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Seletor de data elegante do Daily View
/// EXTRAÍDO SEM ALTERAÇÕES do daily_view_screen.dart
class DailyDateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final bool isToday;
  final bool isFutureDate;
  final VoidCallback onPreviousDay;
  final VoidCallback onNextDay;
  final VoidCallback onTodayTap;
  final ValueChanged<DateTime> onDateSelected;

  const DailyDateSelector({
    super.key,
    required this.selectedDate,
    required this.isToday,
    required this.isFutureDate,
    required this.onPreviousDay,
    required this.onNextDay,
    required this.onTodayTap,
    required this.onDateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final weekday = DateFormat('EEEE', 'pt_BR').format(selectedDate);
    final weekdayCapitalized = weekday[0].toUpperCase() + weekday.substring(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38383A),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(
            icon: Icons.chevron_left_rounded,
            onTap: onPreviousDay,
          ),
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: Color(0xFFFFD60A),
                            surface: Color(0xFF1C1C1E),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (date != null) {
                    onDateSelected(date);
                  }
                },
                borderRadius: BorderRadius.circular(8),
                splashColor: const Color(0xFF98989D).withValues(alpha: 0.3),
                highlightColor: const Color(0xFF98989D).withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFFFFFF),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            weekdayCapitalized,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF98989D),
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (!isToday) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isFutureDate
                                    ? const Color(0xFFFF9F0A)
                                    : const Color(0xFF636366)),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isFutureDate ? 'Futuro' : 'Passado',
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF000000),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isToday)
            _buildNavButton(
              icon: Icons.chevron_right_rounded,
              onTap: onNextDay,
            )
          else
            Row(
              children: [
                _buildTodayButton(onTodayTap),
                const SizedBox(width: 6),
                _buildNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: onNextDay,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNavButton({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        splashColor: const Color(0xFF98989D).withValues(alpha: 0.3),
        highlightColor: const Color(0xFF98989D).withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: const Color(0xFF98989D), size: 20),
        ),
      ),
    );
  }

  Widget _buildTodayButton(VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Material(
        color: const Color(0xFFFFD60A),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          splashColor: const Color(0xFF98989D).withValues(alpha: 0.3),
          highlightColor: const Color(0xFF98989D).withValues(alpha: 0.15),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(Icons.today, size: 12, color: Color(0xFF000000)),
                SizedBox(width: 4),
                Text(
                  'Hoje',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
