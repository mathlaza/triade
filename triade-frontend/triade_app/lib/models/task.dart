import 'package:triade_app/config/constants.dart';

class Task {
  final int id;
  final String title;
  final EnergyLevel energyLevel;
  final int durationMinutes;
  final TaskStatus status;
  final DateTime dateScheduled;
  final String? scheduledTime; // HH:MM format
  final String? roleTag;
  final String? contextTag;
  final String? delegatedTo;
  final DateTime? followUpDate;
  final bool isRepeatable;
  final int repeatCount;
  final int? repeatDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.energyLevel, 
    required this.durationMinutes,
    required this.status,
    required this.dateScheduled,
    this.scheduledTime,
    this.roleTag,
    this.contextTag,
    this.delegatedTo,
    this.followUpDate,
    this.isRepeatable = false,
    this.repeatCount = 0,
    this.repeatDays, // 🔥 Remove o = 7 para aceitar null
    required this.createdAt,
    required this.updatedAt,
  });

  // Converter de JSON (resposta da API)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      energyLevel: EnergyLevel.fromString(json['energy_level']),
      durationMinutes: json['duration_minutes'],
      status: TaskStatus.fromString(json['status']),
      dateScheduled: DateTime.parse(json['date_scheduled']),
      scheduledTime: json['scheduled_time'],
      roleTag: json['role_tag'],
      contextTag: json['context_tag'],
      delegatedTo: json['delegated_to'],
      followUpDate: json['follow_up_date'] != null 
          ? DateTime.parse(json['follow_up_date']) 
          : null,
      isRepeatable: json['is_repeatable'] ?? false,
      repeatCount: (json['repeat_count'] ?? 0) == 0 && (json['is_repeatable'] ?? false) 
        ? 1 
        : (json['repeat_count'] ?? 0),
      repeatDays: json['repeat_days'] ?? 7,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Converter para JSON (enviar para API)
  Map<String, dynamic> toJson() {
  return {
    'title': title,
    'energy_level': energyLevel.value,
    'duration_minutes': durationMinutes,
    'date_scheduled': _formatDate(dateScheduled),
    'status': status.value,
    if (scheduledTime != null) 'scheduled_time': scheduledTime,
    if (roleTag != null) 'role_tag': roleTag,
    if (contextTag != null) 'context_tag': contextTag,
    if (delegatedTo != null) 'delegated_to': delegatedTo,
    if (followUpDate != null) 'follow_up_date': _formatDate(followUpDate!),
    'is_repeatable': isRepeatable,
    'repeat_count': repeatCount,
    'repeat_days': repeatDays,
  };
}


  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Formatar duração para exibição
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '${durationMinutes}min';
    }
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
  }

  // Verificar se está vencida (para delegações)
  bool get isOverdue {
    if (status != TaskStatus.delegated || followUpDate == null) {
      return false;
    }
    return followUpDate!.isBefore(DateTime.now());
  }

  // Copiar com alterações
  Task copyWith({
    int? id,
    String? title,
    EnergyLevel? energyLevel,
    int? durationMinutes,
    TaskStatus? status,
    DateTime? dateScheduled,
    String? scheduledTime,
    bool clearScheduledTime = false,
    String? roleTag,
    String? contextTag,
    String? delegatedTo,
    DateTime? followUpDate,
    bool? isRepeatable,
    int? repeatCount,
    int? repeatDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      energyLevel: energyLevel ?? this.energyLevel,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      dateScheduled: dateScheduled ?? this.dateScheduled,
      scheduledTime: clearScheduledTime ? null : (scheduledTime ?? this.scheduledTime),
      roleTag: roleTag ?? this.roleTag,
      contextTag: contextTag ?? this.contextTag,
      delegatedTo: delegatedTo ?? this.delegatedTo,
      followUpDate: followUpDate ?? this.followUpDate,
      isRepeatable: isRepeatable ?? this.isRepeatable,
      repeatCount: repeatCount ?? this.repeatCount,
      repeatDays: repeatDays ?? this.repeatDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
