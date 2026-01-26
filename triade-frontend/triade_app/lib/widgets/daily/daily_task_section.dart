import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/widgets/task_card.dart';
import 'package:triade_app/screens/add_task_screen.dart';
import 'package:triade_app/services/sound_service.dart';

/// Seção de tarefas por categoria de energia
/// EXTRAÍDO SEM ALTERAÇÕES do daily_view_screen.dart
class DailyTaskSection extends StatelessWidget {
  final String title;
  final List<Task> tasks;
  final Color energyColor;
  final DateTime selectedDate;
  final VoidCallback onDataChanged;

  const DailyTaskSection({
    super.key,
    required this.title,
    required this.tasks,
    required this.energyColor,
    required this.selectedDate,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 160,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 1),
          padding: const EdgeInsets.fromLTRB(4, 1.5, 12, 1.5),
          decoration: BoxDecoration(
            color: energyColor.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: energyColor.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.3,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        ...tasks.map((task) {
          final provider = context.read<TaskProvider>();

          Future<void> deleteCb() async {
            await provider.deleteTask(task.id);
          }

          final card = TaskCard(
            task: task,
            isFutureRepeatable: false,
            onLongPress: () async {
              HapticFeedback.mediumImpact();
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddTaskScreen(
                    selectedDate: task.dateScheduled,
                    taskToEdit: task,
                  ),
                ),
              );
              if (result == true) {
                onDataChanged();
              }
            },
            onDelete: deleteCb,
            onToggleDone: () async {
              HapticFeedback.lightImpact();
              SoundService().playClick();
              await provider.toggleTaskDone(task.id);
            },
          );

          if (!task.isRepeatable) return card;

          return Dismissible(
            key: ValueKey(
                'task_${task.id}_${task.dateScheduled.toIso8601String()}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              await deleteCb();
              return true;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            child: card,
          );
        }),
      ],
    );
  }
}
