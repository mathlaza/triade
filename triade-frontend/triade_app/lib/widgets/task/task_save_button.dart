import 'package:flutter/material.dart';
import 'package:triade_app/widgets/task/task_form_styles.dart';

/// Botão de salvar tarefa
/// EXTRAÍDO SEM ALTERAÇÕES do add_task_screen.dart
class TaskSaveButton extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onPressed;

  const TaskSaveButton({
    super.key,
    required this.isEditing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: TaskFormStyles.primaryGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: TaskFormStyles.accentColor.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isEditing ? Icons.check : Icons.add,
              color: Colors.black87,
            ),
            const SizedBox(width: 8),
            Text(
              isEditing ? 'Atualizar Tarefa' : 'Criar Tarefa',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
