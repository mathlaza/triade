import 'package:flutter/material.dart';
import 'package:triade_app/models/task.dart';

// Premium Dark Theme Colors
const _kTextPrimary = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF8E8E93);
// ✅ Cor diferenciada para done - Azul suave (diferente de Renovação verde)
const _doneTaskBackgroundColor = Color(0xFF64D2FF); // Azul iOS

/// Conteúdo visual do card de tarefa semanal
class WeeklyTaskCardContent extends StatelessWidget {
  final Task task;
  final Color contextColor;
  final bool isDone;
  final Color activeBackgroundColor;
  final Color activeBorderColor;

  const WeeklyTaskCardContent({
    super.key,
    required this.task,
    required this.contextColor,
    required this.isDone,
    required this.activeBackgroundColor,
    required this.activeBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ Cores adaptadas para tema escuro - opacidade aumentada para melhor leitura
    final bgColor = isDone
        ? _doneTaskBackgroundColor.withValues(alpha: 0.25)
        : task.energyLevel.color.withValues(alpha: 0.60);
    final borderColor = isDone
        ? _doneTaskBackgroundColor.withValues(alpha: 0.7)
        : task.energyLevel.color.withValues(alpha: 0.6);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // ✅ Indicador de done (checkmark) ou energia
          if (isDone)
            Container(
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(right: 6),
              decoration: const BoxDecoration(
                color: _doneTaskBackgroundColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 12,
                color: Colors.black,
              ),
            )
          else
            Container(
              width: 3,
              height: 24,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: task.energyLevel.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    decorationColor: _kTextSecondary,
                    color: isDone ? _kTextSecondary : _kTextPrimary,
                  ),
                ),
                if (task.contextTag != null || task.roleTag != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        if (task.contextTag != null) _buildContextBadge(),
                        if (task.roleTag != null) _buildRoleBadge(),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (task.isRepeatable) _buildRepeatSeriesBadge(),
              if (task.isRepeatable) const SizedBox(height: 2),
              _buildDurationBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContextBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF000000).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: contextColor.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.label, size: 9, color: contextColor),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              task.contextTag!,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                color: contextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF000000).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: const Color(0xFF64D2FF).withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person, size: 9, color: Color(0xFF64D2FF)),
          const SizedBox(width: 2),
          Flexible(
            child: Text(
              task.roleTag!,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 8,
                color: Color(0xFF64D2FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepeatSeriesBadge() {
    if (!task.isRepeatable) return const SizedBox.shrink();

    final n = task.repeatCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF000000).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.teal,
          width: 1,
        ),
      ),
      child: Text(
        '#$n',
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: Colors.teal,
        ),
      ),
    );
  }

  Widget _buildDurationBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: const Color(0xFF000000).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: _kTextSecondary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Text(
        '${(task.durationMinutes / 60).toStringAsFixed(1)}h',
        style: const TextStyle(
          fontSize: 8,
          color: _kTextSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
