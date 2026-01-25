import 'package:flutter/material.dart';
import '../../models/task.dart';
import 'follow_up_styles.dart';

/// Diálogo de confirmação para reassumir tarefa delegada
class ReassignConfirmDialog extends StatelessWidget {
  final Task task;

  const ReassignConfirmDialog({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: followUpSurfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: followUpBorderColor),
      ),
      title: const Row(
        children: [
          Icon(Icons.undo_rounded, color: followUpAccentGold, size: 24),
          SizedBox(width: 12),
          Text(
            'Reassumir Tarefa?',
            style: TextStyle(
              color: followUpTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: followUpCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: followUpBorderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.task_alt_rounded, color: followUpAccentGold, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      color: followUpTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Esta tarefa voltará para sua lista e será removida das delegações.',
            style: TextStyle(color: followUpTextSecondary, fontSize: 14),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: followUpTextSecondary),
          ),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: followUpAccentGold,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          icon: const Icon(Icons.undo_rounded, size: 18),
          label: const Text('Reassumir', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }

  /// Método estático para mostrar o diálogo e retornar o resultado
  static Future<bool> show(BuildContext context, Task task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => ReassignConfirmDialog(task: task),
    );
    return result ?? false;
  }
}
