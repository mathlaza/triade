import 'package:flutter/material.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/config/constants.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleDone;
  final bool isFutureRepeatable;
  final bool isFutureDate;

  const TaskCard({
    super.key,
    required this.task,
    this.onLongPress,
    this.onDelete,
    this.onToggleDone,
    this.isFutureRepeatable = false,
    this.isFutureDate = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.done;
    final isDelegated = task.delegatedTo != null && task.delegatedTo!.isNotEmpty;
    final showSeriesNumber = task.isRepeatable && task.repeatCount >= 1;

    final categoryColor = task.triadCategory.color;
    final contextChipColor = ContextColors.getColor(task.contextTag);

    final cardBackgroundColor = isDone ? Colors.green.shade50 : Colors.white;
    final cardBorderColor = isDone ? Colors.green.shade50 : categoryColor;

    return Dismissible(
      key: Key('${task.id}_${task.dateScheduled.toIso8601String()}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      confirmDismiss: (direction) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Excluir tarefa?'),
            content: Text('Tem certeza que deseja excluir "${task.title}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Excluir'),
              ),
            ],
          ),
        );
        if (result == true) {
          onDelete?.call();
        }
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        elevation: 2,
        color: cardBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: cardBorderColor,
            width: 3,
          ),
        ),
        child: InkWell(
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Checkbox
                    if (!isFutureRepeatable && onToggleDone != null)
                      GestureDetector(
                        onTap: onToggleDone,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isDone ? Colors.green.shade400 : Colors.white,
                            border: Border.all(
                              color: isDone ? Colors.green.shade400 : Colors.grey.shade400,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: isDone
                              ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Colors.grey.shade600 : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '${(task.durationMinutes / 60).toStringAsFixed(1)}h',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (task.contextTag != null)
                        _buildChip(
                          icon: Icons.label,
                          label: task.contextTag!,
                          color: contextChipColor,
                        ),
                      if (task.roleTag != null)
                        _buildChip(
                          icon: Icons.person,
                          label: task.roleTag!,
                          color: Colors.blue,
                        ),
                      if (isDelegated)
                        _buildChip(
                          icon: Icons.forward,
                          label: 'Delegada',
                          color: Colors.brown,
                        ),
                      if (task.isRepeatable)
                        _buildChip(
                          icon: Icons.repeat,
                          label: 'Repetível',
                          color: Colors.teal,
                        ),
                      if (showSeriesNumber)
                        _buildChip(
                          icon: Icons.numbers,
                          label: 'Série ${task.repeatCount}',
                          color: Colors.purple,
                        ),
                      if (isFutureDate)
                        _buildChip(
                          icon: Icons.schedule,
                          label: 'Dia Futuro',
                          color: Colors.grey,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip({required IconData icon, required String label, required Color color}) {
    return Chip(
      avatar: Icon(icon, color: color, size: 16),
      label: Text(label),
      labelStyle: TextStyle(color: color, fontSize: 11),
      backgroundColor: color.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    );
  }
}