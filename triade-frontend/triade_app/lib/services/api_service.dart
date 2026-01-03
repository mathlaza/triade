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

  Future<Task> createTask(Task task) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(task.toJson()),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Task.fromJson(data['task']);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Erro ao criar tarefa');
    }
  }

  Future<Task> updateTask(int taskId, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$taskId'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return Task.fromJson(data['task']);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Erro ao atualizar tarefa');
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
        'available_hours': hours,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return DailyConfig.fromJson(data['config']);
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

  // ==================== HELPERS ====================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
