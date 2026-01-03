import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/models/daily_config.dart';
import 'package:triade_app/models/daily_summary.dart';
import 'package:triade_app/models/triad_stats.dart';

class ApiService {
  final String baseUrl = AppConstants.apiBaseUrl;

  // ==================== TASKS ====================

  Future<Map<String, dynamic>> getDailyTasks(DateTime date) async {
    final dateStr = _formatDate(date);
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/daily?date=$dateStr'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'tasks': (data['tasks'] as List).map((e) => Task.fromJson(e)).toList(),
        'summary': DailySummary.fromJson(data),
      };
    } else {
      throw Exception('Erro ao buscar tarefas: ${response.body}');
    }
  }

  // NOVO: Buscar tarefas delegadas (Follow-up)
  Future<List<Task>> getDelegatedTasks() async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/delegated'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['tasks'] as List)
          .map((e) => Task.fromJson(e))
          .toList();
    } else {
      throw Exception('Erro ao buscar tarefas delegadas: ${response.body}');
    }
  }


Future<Map<String, dynamic>> getWeeklyTasks(DateTime startDate, DateTime endDate) async {
  final start = _formatDate(startDate);
  final end = _formatDate(endDate);

  final response = await http.get(
    Uri.parse('$baseUrl/tasks/weekly?start_date=$start&end_date=$end'),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return {
      'tasks': (data['tasks'] as List).map((e) => Task.fromJson(e)).toList(),
      'daily_configs': Map<String, double>.from(data['daily_configs']),
      'start_date': data['start_date'],
      'end_date': data['end_date'],
    };
  } else {
    throw Exception('Erro ao buscar tarefas semanais: ${response.body}');
  }
}

// NOVO: Mover tarefa para outro dia
Future<Task> moveTaskToDate(int taskId, DateTime newDate) async {
  return await updateTask(taskId, {
    'date_scheduled': _formatDate(newDate),
  });
}



  Future<List<Task>> getPendingReview(DateTime date) async {
    final dateStr = _formatDate(date);
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/pending_review?date=$dateStr'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['pending_tasks'] as List)
          .map((e) => Task.fromJson(e))
          .toList();
    } else {
      throw Exception('Erro ao buscar tarefas pendentes: ${response.body}');
    }
  }

  // ==================== CREATE & UPDATE ====================

  Future<Task> createTask(Task task) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'title': task.title,
        'triad_category': task.triadCategory.toString().split('.').last.toUpperCase(),
        'duration_minutes': task.durationMinutes,
        'date_scheduled': _formatDate(task.dateScheduled),
        'role_tag': task.roleTag,
        'context_tag': task.contextTag,
        'delegated_to': task.delegatedTo,
        'follow_up_date': task.followUpDate != null ? _formatDate(task.followUpDate!) : null,
        'is_repeatable': task.isRepeatable,
        'repeat_count': task.repeatCount,
        'repeat_days': task.repeatDays,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      // CORREÇÃO: O create_task do Python retorna o objeto DIRETO.
      // Lemos o JSON inteiro e passamos para o Task.fromJson.
      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return Task.fromJson(data);
    } else {
      throw Exception('Falha ao criar tarefa: ${response.body}');
    }
  }

    Future<Task> updateTask(int id, Map<String, dynamic> updates) async {
    // Formatação de datas e campos para o backend
    if (updates.containsKey('dateScheduled')) {
      if (updates['dateScheduled'] is DateTime) {
        updates['date_scheduled'] = _formatDate(updates['dateScheduled']);
      }
      updates.remove('dateScheduled');
    }

    if (updates.containsKey('followUpDate')) {
      if (updates['followUpDate'] is DateTime) {
        updates['follow_up_date'] = _formatDate(updates['followUpDate']);
      } else if (updates['followUpDate'] == "" || updates['followUpDate'] == null) {
        // ✅ Garante que string vazia ou null passem como null ou string vazia para o backend
        updates['follow_up_date'] = updates['followUpDate'];
      }
      updates.remove('followUpDate');
    }

    // ✅ O BLOCO QUE FALTAVA: Traduzir delegatedTo para delegated_to
    if (updates.containsKey('delegatedTo')) {
      updates['delegated_to'] = updates['delegatedTo'];
      updates.remove('delegatedTo');
    }

    // Mapear camelCase para snake_case (Outros campos)
    if (updates.containsKey('durationMinutes')) {
      updates['duration_minutes'] = updates['durationMinutes'];
      updates.remove('durationMinutes');
    }
    if (updates.containsKey('isRepeatable')) {
      updates['is_repeatable'] = updates['isRepeatable'];
      updates.remove('isRepeatable');
    }
    if (updates.containsKey('repeatCount')) {
      updates['repeat_count'] = updates['repeatCount'];
      updates.remove('repeatCount');
    }
    if (updates.containsKey('repeatDays')) {
      updates['repeat_days'] = updates['repeatDays'];
      updates.remove('repeatDays');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return Task.fromJson(data['task']);
    } else {
      throw Exception('Falha ao atualizar tarefa: ${response.body}');
    }
  }





  Future<void> deleteTask(int taskId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$taskId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir tarefa');
    }
  }

  // ==================== STATS ====================

  Future<TriadStats> getTriadStats(DateTime startDate, DateTime endDate) async {
    final start = _formatDate(startDate);
    final end = _formatDate(endDate);
    final response = await http.get(
      Uri.parse('$baseUrl/stats/triad?start_date=$start&end_date=$end'),
    );

    if (response.statusCode == 200) {
      return TriadStats.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erro ao buscar estatísticas');
    }
  }

  // ==================== CONFIG ====================

      Future<DailyConfig> setDailyConfig(DateTime date, double hours) async {
    final response = await http.post(
      Uri.parse('$baseUrl/config/daily'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'date': _formatDate(date),
        'hours': hours,
      }),
    );

    if (response.statusCode == 200) {
      // CORREÇÃO: Adicionado id: 0 para satisfazer o construtor
      return DailyConfig(
        id: 0, 
        date: date, 
        availableHours: hours
      );
    } else {
      throw Exception('Erro ao salvar configuração');
    }
  }



  Future<double> getDailyConfig(DateTime date) async {
    final dateStr = _formatDate(date);
    final response = await http.get(
      Uri.parse('$baseUrl/config/daily?date=$dateStr'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['available_hours'].toDouble();
    } else {
      return 8.0; // Padrão
    }
  }




    // Toggle específico para tarefas repetíveis
  Future<void> toggleRepeatableTask(int taskId, DateTime date) async {
    final dateStr = _formatDate(date);
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/$taskId/toggle-date'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'date': dateStr}),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar status repetível: ${response.body}');
    }
  }


  // ==================== HELPERS ====================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
