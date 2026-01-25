import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../../config/constants.dart';
import 'follow_up_styles.dart';

/// Card de tarefa delegada com suporte a swipe para reassumir
class DelegatedTaskCard extends StatelessWidget {
  final Task task;
  final bool isCompleted;
  final Color statusColor;
  final VoidCallback onToggleCompletion;
  final Future<bool> Function() onConfirmReassign;
  final VoidCallback onReassign;

  const DelegatedTaskCard({
    super.key,
    required this.task,
    required this.isCompleted,
    required this.statusColor,
    required this.onToggleCompletion,
    required this.onConfirmReassign,
    required this.onReassign,
  });

  Color _getEnergyColor(EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.highEnergy:
        return followUpErrorRed;
      case EnergyLevel.lowEnergy:
        return followUpTextSecondary;
      case EnergyLevel.renewal:
        return followUpSuccessGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('delegated_${task.id}'),
      direction: isCompleted ? DismissDirection.none : DismissDirection.endToStart,
      confirmDismiss: (_) => onConfirmReassign(),
      onDismissed: (_) => onReassign(),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [followUpAccentGold, followUpAccentOrange],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.undo_rounded, color: Colors.black, size: 24),
            SizedBox(width: 8),
            Text(
              'Reassumir',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isCompleted 
              ? followUpSuccessGreen.withValues(alpha: 0.08)
              : followUpSurfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted 
                ? followUpSuccessGreen.withValues(alpha: 0.3)
                : followUpBorderColor,
            width: isCompleted ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com energia e status
              Row(
                children: [
                  // Badge de energia
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _getEnergyColor(task.energyLevel).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getEnergyColor(task.energyLevel).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      task.energyLevel.label,
                      style: TextStyle(
                        color: _getEnergyColor(task.energyLevel),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Indicador de status
                  if (!isCompleted)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Row com checkbox e título
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox premium
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onToggleCompletion();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? const LinearGradient(
                                colors: [followUpSuccessGreen, Color(0xFF28A745)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isCompleted ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCompleted ? followUpSuccessGreen : followUpTextSecondary,
                          width: 2,
                        ),
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                  color: followUpSuccessGreen.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Título da tarefa
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        color: isCompleted ? followUpTextSecondary : followUpTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: followUpTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Info de delegação
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted ? followUpSuccessGreen.withValues(alpha: 0.1) : followUpCardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted ? followUpSuccessGreen.withValues(alpha: 0.2) : followUpBorderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [followUpSuccessGreen, followUpSuccessGreen.withValues(alpha: 0.7)],
                              )
                            : const LinearGradient(
                                colors: [followUpAccentGold, followUpAccentOrange],
                              ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : Icons.person_outline_rounded,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delegada para',
                            style: TextStyle(
                              color: isCompleted ? followUpSuccessGreen.withValues(alpha: 0.7) : followUpTextSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            task.delegatedTo ?? 'N/A',
                            style: TextStyle(
                              color: isCompleted ? followUpSuccessGreen : followUpTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isCompleted ? followUpSuccessGreen : statusColor).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isCompleted ? followUpSuccessGreen : statusColor).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: isCompleted ? followUpSuccessGreen : statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            task.followUpDate != null
                                ? DateFormat('dd/MM').format(task.followUpDate!)
                                : 'Sem data',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCompleted ? followUpSuccessGreen : statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Hint de swipe (só se não estiver concluída)
              if (!isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.swipe_left_rounded,
                        size: 14,
                        color: followUpTextSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Deslize para reassumir',
                        style: TextStyle(
                          color: followUpTextSecondary.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
