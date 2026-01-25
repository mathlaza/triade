import 'package:flutter/material.dart';
import 'package:triade_app/widgets/task/task_form_styles.dart';

/// Switch de tarefa repetível
/// EXTRAÍDO SEM ALTERAÇÕES do add_task_screen.dart
class RepeatableSwitch extends StatelessWidget {
  final bool isRepeatable;
  final bool isDisabled;
  final bool isDelegated;
  final bool isFutureTask;
  final ValueChanged<bool> onChanged;

  const RepeatableSwitch({
    super.key,
    required this.isRepeatable,
    required this.isDisabled,
    required this.isDelegated,
    required this.isFutureTask,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: TaskFormStyles.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.repeat,
            color: isDisabled ? Colors.white38 : TaskFormStyles.accentColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarefa repetível',
                  style: TextStyle(
                    color: isDisabled ? Colors.white38 : Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (isDisabled)
                  Text(
                    isDelegated 
                        ? 'Não disponível para tarefas delegadas' 
                        : 'Não disponível para tarefas futuras',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
          Switch(
            value: isRepeatable,
            onChanged: isDisabled ? null : onChanged,
            activeThumbColor: TaskFormStyles.accentColor,
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}
