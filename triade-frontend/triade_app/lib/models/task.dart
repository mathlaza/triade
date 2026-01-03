import 'package:triade_app/config/constants.dart';

class Task {
  final int id;
  final String title;
  final TriadCategory triadCategory;
  final int durationMinutes;
  final TaskStatus status;
  final DateTime dateScheduled;
  final String? roleTag;
  final String? contextTag;
  final String? delegatedTo;
  final DateTime? followUpDate;
  final bool isRepeatable;
  final int repeatCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.triadCategory,
    required this.durationMinutes,
    required this.status,
    required this.dateScheduled,
    this.roleTag,
    this.contextTag,
    this.delegatedTo,
    this.followUpDate,
    this.isRepeatable = false,
    this.repeatCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Converter de JSON (resposta da API)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      triadCategory: TriadCategory.fromString(json['triad_category']),
      durationMinutes: json['duration_minutes'],
      status: TaskStatus.fromString(json['status']),
      dateScheduled: DateTime.parse(json['date_scheduled']),
      roleTag: json['role_tag'],
      contextTag: json['context_tag'],
      delegatedTo: json['delegated_to'],
      followUpDate: json['follow_up_date'] != null 
          ? DateTime.parse(json['follow_up_date']) 
          : null,
      isRepeatable: json['is_repeatable'] ?? false,
      repeatCount: json['repeat_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Converter para JSON (enviar para API)
  Map<String, dynamic> toJson() {
  return {
    'title': title,
    'triad_category': triadCategory.value,
    'duration_minutes': durationMinutes,
    'date_scheduled': _formatDate(dateScheduled),
    'status': status.value,
    if (roleTag != null) 'role_tag': roleTag,
    if (contextTag != null) 'context_tag': contextTag,
    if (delegatedTo != null) 'delegated_to': delegatedTo,
    if (followUpDate != null) 'follow_up_date': _formatDate(followUpDate!),
    'is_repeatable': isRepeatable,

    // ✅ IMPORTANTE: manter contador no backend (se o backend aceitar)
    'repeat_count': repeatCount,
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
    TriadCategory? triadCategory,
    int? durationMinutes,
    TaskStatus? status,
    DateTime? dateScheduled,
    String? roleTag,
    String? contextTag,
    String? delegatedTo,
    DateTime? followUpDate,
    bool? isRepeatable,
    int? repeatCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      triadCategory: triadCategory ?? this.triadCategory,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      dateScheduled: dateScheduled ?? this.dateScheduled,
      roleTag: roleTag ?? this.roleTag,
      contextTag: contextTag ?? this.contextTag,
      delegatedTo: delegatedTo ?? this.delegatedTo,
      followUpDate: followUpDate ?? this.followUpDate,
      isRepeatable: isRepeatable ?? this.isRepeatable,
      repeatCount: repeatCount ?? this.repeatCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
