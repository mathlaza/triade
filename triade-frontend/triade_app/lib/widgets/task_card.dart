import 'package:flutter/material.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/config/constants.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleDone;
  final bool isFutureRepeatable;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onDelete,
    this.onToggleDone,
    this.isFutureRepeatable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task.status == TaskStatus.done;
    final isDelegated = task.status == TaskStatus.delegated;
    final showSeriesNumber = task.isRepeatable && task.repeatCount >= 1;

    return Dismissible(
      key: Key('${task.id}_${task.dateScheduled.toIso8601String()}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white, size: 32),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: task.triadCategory.color,
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Categoria + Botão Editar + Checkbox
                  Row(
                    children: [
                      // Categoria Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: task.triadCategory.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          task.triadCategory.label,
                          style: TextStyle(
                            color: task.triadCategory.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),

                      // Botão Editar (só aparece se NÃO for repetível futura)
                      if (!isFutureRepeatable) ...[
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              debugPrint('✏️ Editar clicado - Task ID: ${task.id}');
                              onTap?.call();
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                Icons.edit,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],

                      const Spacer(),

                      // Checkbox ISOLADO (só aparece se NÃO for delegada E NÃO for repetível futura)
                      if (!isDelegated && !isFutureRepeatable)
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              debugPrint('✅ Checkbox clicado - Task ID: ${task.id}');
                              onToggleDone?.call();
                            },
                            borderRadius: BorderRadius.circular(50),
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Icon(
                                isDone ? Icons.check_circle : Icons.circle_outlined,
                                color: isDone ? Colors.green : Colors.grey.shade600,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Título
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Duração + Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildChip(
                        icon: Icons.timer,
                        label: task.formattedDuration,
                        color: Colors.blue,
                      ),
                      if (task.roleTag != null)
                        _buildChip(
                          icon: Icons.person,
                          label: task.roleTag!,
                          color: Colors.purple,
                        ),
                      if (task.contextTag != null)
                        _buildChip(
                          icon: Icons.location_on,
                          label: task.contextTag!,
                          color: Colors.orange,
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
                      if (isFutureRepeatable)
                        _buildChip(
                          icon: Icons.schedule,
                          label: 'Dia Futuro',
                          color: Colors.grey,
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // BADGE DE SÉRIE (canto superior direito, grande e visível)
            if (showSeriesNumber)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        task.triadCategory.color,
                        task.triadCategory.color.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: task.triadCategory.color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.format_list_numbered,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Dia ${task.repeatCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }
}
