import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Modal para selecionar horas disponíveis do dia
/// EXTRAÍDO SEM ALTERAÇÕES do daily_view_screen.dart
class HoursPickerModal extends StatefulWidget {
  final double currentHours;
  final DateTime selectedDate;
  final ValueChanged<double> onSave;

  const HoursPickerModal({
    super.key,
    required this.currentHours,
    required this.selectedDate,
    required this.onSave,
  });

  @override
  State<HoursPickerModal> createState() => _HoursPickerModalState();
  
  /// Mostra o modal como BottomSheet
  static void show(BuildContext context, {
    required double currentHours,
    required DateTime selectedDate,
    required ValueChanged<double> onSave,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return HoursPickerModal(
          currentHours: currentHours,
          selectedDate: selectedDate,
          onSave: onSave,
        );
      },
    );
  }
}

class _HoursPickerModalState extends State<HoursPickerModal> {
  late double selectedHours;

  @override
  void initState() {
    super.initState();
    selectedHours = widget.currentHours;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF48484A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD60A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule,
                  color: Color(0xFF000000),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Horas Disponíveis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat("EEEE, d 'de' MMMM", 'pt_BR').format(widget.selectedDate),
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF98989D),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 24),
          // Hours display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '${selectedHours.toStringAsFixed(1)}h',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFD60A),
                letterSpacing: -1,
              ),
            ),
          ),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFFFFD60A),
              inactiveTrackColor: const Color(0xFF2C2C2E),
              thumbColor: const Color(0xFFFFD60A),
              overlayColor: const Color(0xFFFFD60A).withValues(alpha: 0.2),
              trackHeight: 6,
            ),
            child: Slider(
              value: selectedHours,
              min: 1,
              max: 24,
              divisions: 46, // 0.5h increments
              onChanged: (value) {
                setState(() {
                  selectedHours = (value * 2).round() / 2; // Round to 0.5
                });
              },
            ),
          ),
          // Min/Max labels
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1h',
                    style: TextStyle(color: Color(0xFF98989D), fontSize: 12)),
                Text('24h',
                    style: TextStyle(color: Color(0xFF98989D), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Quick select buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [4.0, 6.0, 8.0, 10.0, 12.0].map((hours) {
              final isSelected = selectedHours == hours;
              return Material(
                color: isSelected
                    ? const Color(0xFFFFD60A)
                    : const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      selectedHours = hours;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  splashColor: const Color(0xFF98989D).withValues(alpha: 0.3),
                  highlightColor: const Color(0xFF98989D).withValues(alpha: 0.15),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFD60A)
                            : const Color(0xFF38383A),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${hours.toInt()}h',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? const Color(0xFF000000)
                            : const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          // Save button
          SizedBox(
            width: double.infinity,
            child: Material(
              color: const Color(0xFFFFD60A),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.onSave(selectedHours);
                },
                borderRadius: BorderRadius.circular(14),
                splashColor: const Color(0xFF98989D).withValues(alpha: 0.3),
                highlightColor: const Color(0xFF98989D).withValues(alpha: 0.15),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Salvar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF000000),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
