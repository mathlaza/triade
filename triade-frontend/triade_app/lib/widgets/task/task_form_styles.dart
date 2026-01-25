import 'package:flutter/material.dart';

/// Cores e estilos do formulário de tarefas
/// EXTRAÍDO SEM ALTERAÇÕES do add_task_screen.dart
class TaskFormStyles {
  TaskFormStyles._();
  
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFFFFD60A), Color(0xFFFFCC00)],
  );
  static const darkBackground = Color(0xFF1C1C1E);
  static const cardBackground = Color(0xFF2C2C2E);
  static const accentColor = Color(0xFFFFD60A);

  static InputDecoration buildInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? helper,
    String? counter,
    bool enabled = true,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: enabled ? Colors.white70 : Colors.white38,
      ),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white30),
      helperText: helper,
      helperStyle: const TextStyle(color: Colors.white54, fontSize: 12),
      counterText: counter,
      counterStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: accentColor.withValues(alpha: 0.8)),
      filled: true,
      fillColor: enabled ? cardBackground : cardBackground.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }
}

/// Header de seção do formulário
/// EXTRAÍDO SEM ALTERAÇÕES do add_task_screen.dart
class TaskFormSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const TaskFormSectionHeader({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: TaskFormStyles.accentColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
