import 'package:triade_app/config/constants.dart';

class HistoryTask {
  final int id;
  final String title;
  final EnergyLevel energyLevel;
  final int durationMinutes;
  final DateTime completedAt;
  final DateTime dateScheduled;
  final String? contextTag;
  final String? roleTag;

  HistoryTask({
    required this.id,
    required this.title,
    required this.energyLevel,
    required this.durationMinutes,
    required this.completedAt,
    required this.dateScheduled,
    this.contextTag,
    this.roleTag,
  });

  factory HistoryTask.fromJson(Map<String, dynamic> json) {
  return HistoryTask(
    id: json['id'],
    title: json['title'],
    energyLevel: EnergyLevel.fromString(json['energy_level']),
    durationMinutes: json['duration_minutes'],
    // 🔥 MUDANÇA: Parse direto, sem conversão de timezone
    completedAt: DateTime.parse(json['completed_at']),
    dateScheduled: DateTime.parse(json['date_scheduled']),
    contextTag: json['context_tag'],
    roleTag: json['role_tag'],
  );
}

  // 🔥 CORREÇÃO: Comparação de performance com timezone correto
  PerformanceIndicator get performanceIndicator {
    // Usar apenas DATAS (sem hora) para evitar problemas de timezone
    final completedDate = DateTime(
      completedAt.year, 
      completedAt.month, 
      completedAt.day
    );
    
    final scheduledDate = DateTime(
      dateScheduled.year, 
      dateScheduled.month, 
      dateScheduled.day
    );

    if (completedDate.isBefore(scheduledDate)) {
      return PerformanceIndicator.anticipated;
    } else if (completedDate.isAfter(scheduledDate)) {
      return PerformanceIndicator.delayed;
    } else {
      return PerformanceIndicator.onTime;
    }
  }

  String get formattedDuration {
    if (durationMinutes < 60) {
      return '${durationMinutes}min';
    }
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
  }
}

enum PerformanceIndicator {
  anticipated,  // Antecipada
  onTime,       // No Prazo
  delayed       // Atrasada
}