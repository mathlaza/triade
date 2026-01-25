import 'package:flutter/material.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/widgets/task/task_form_styles.dart';

/// Seletor de nível de energia
/// EXTRAÍDO SEM ALTERAÇÕES do add_task_screen.dart
class EnergyLevelSelector extends StatelessWidget {
  final EnergyLevel selectedLevel;
  final ValueChanged<EnergyLevel> onChanged;

  const EnergyLevelSelector({
    super.key,
    required this.selectedLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Ordem correta: Alta Energia, Renovação, Baixa Energia
    final orderedLevels = [
      EnergyLevel.highEnergy,
      EnergyLevel.renewal,
      EnergyLevel.lowEnergy,
    ];
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TaskFormStyles.cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: orderedLevels.map((level) {
          final isSelected = selectedLevel == level;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(level),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? level.color.withValues(alpha: 0.3) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: isSelected
                      ? Border.all(color: level.color, width: 2)
                      : null,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: level.color,
                        shape: BoxShape.circle,
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: level.color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      level.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white60,
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
