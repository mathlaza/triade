import 'package:flutter/material.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/widgets/task/task_form_styles.dart';

/// Dropdown de contexto para formulário de tarefa
/// EXTRAÍDO SEM ALTERAÇÕES do add_task_screen.dart
class ContextDropdown extends StatelessWidget {
  final String? selectedContext;
  final ValueChanged<String?> onChanged;

  const ContextDropdown({
    super.key,
    required this.selectedContext,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: TaskFormStyles.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonFormField<String>(
        initialValue: selectedContext,
        dropdownColor: TaskFormStyles.cardBackground,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.label_outline, color: TaskFormStyles.accentColor),
          labelText: 'Contexto',
          labelStyle: TextStyle(color: Colors.white70),
        ),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('Nenhum', style: TextStyle(color: Colors.white54)),
          ),
          ...ContextColors.colors.keys.map((contextTag) {
            final color = ContextColors.getColor(contextTag);
            return DropdownMenuItem(
              value: contextTag,
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(contextTag, style: const TextStyle(color: Colors.white)),
                ],
              ),
            );
          }),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
