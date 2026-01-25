import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:triade_app/widgets/task/task_form_styles.dart';

/// Seção de follow-up para tarefas delegadas
/// EXTRAÍDO SEM ALTERAÇÕES do add_task_screen.dart
class FollowUpSection extends StatelessWidget {
  final DateTime? followUpDate;
  final ValueChanged<DateTime?> onDateChanged;

  const FollowUpSection({
    super.key,
    required this.followUpDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange.shade300, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tarefa delegada. Defina quando fazer o follow-up.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: followUpDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                onDateChanged(date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TaskFormStyles.cardBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.orange, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      followUpDate != null
                          ? 'Follow-up: ${DateFormat('dd/MM/yyyy').format(followUpDate!)}'
                          : 'Definir data de follow-up',
                      style: TextStyle(
                        fontSize: 14,
                        color: followUpDate != null ? Colors.white : Colors.white54,
                      ),
                    ),
                  ),
                  if (followUpDate != null)
                    GestureDetector(
                      onTap: () => onDateChanged(null),
                      child: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
