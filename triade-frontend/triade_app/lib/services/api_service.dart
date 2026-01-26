import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/models/daily_config.dart';
import 'package:triade_app/models/daily_summary.dart';
import 'package:triade_app/models/energy_stats.dart';
import 'package:triade_app/services/auth_service.dart';

class ApiService {
  final String baseUrl = AppConstants.apiBaseUrl;
  final AuthService _authService = AuthService();

  /// Helper para construir headers com autenticação
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Wrapper para requisições autenticadas com refresh automático
  Future<http.Response> _authenticatedRequest(
    Future<http.Response> Function(Map<String, String> headers) request,
  ) async {
    var headers = await _getAuthHeaders();
    var response = await request(headers);

    // Se token expirou, tenta refresh e refaz a requisição
    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshAccessToken();
      if (refreshed) {
        headers = await _getAuthHeaders();
        response = await request(headers);
      }
    }

    return response;
  }

  // ==================== TASKS ====================

  Future<Map<String, dynamic>> getDailyTasks(DateTime date) async {
    final dateStr = _formatDate(date);
    
    final response = await _authenticatedRequest(
      (headers) => http.get(
        Uri.parse('$baseUrl/tasks/daily?date=$dateStr'),
        headers: headers,
      ),
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
    final response = await _authenticatedRequest(
      (headers) => http.get(
        Uri.parse('$baseUrl/tasks/delegated'),
        headers: headers,
      ),
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

  final response = await _authenticatedRequest(
    (headers) => http.get(
      Uri.parse('$baseUrl/tasks/weekly?start_date=$start&end_date=$end'),
      headers: headers,
    ),
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
    
    final response = await _authenticatedRequest(
      (headers) => http.get(
        Uri.parse('$baseUrl/tasks/pending_review?date=$dateStr'),
        headers: headers,
      ),
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
  final response = await _authenticatedRequest(
    (headers) => http.post(
      Uri.parse('$baseUrl/tasks'),
      headers: headers,
      body: json.encode({
        'title': task.title,
        'description': task.description,
        'energy_level': task.energyLevel.value,
        'duration_minutes': task.durationMinutes,
        'date_scheduled': _formatDate(task.dateScheduled),
        'scheduled_time': task.scheduledTime,
        'status': task.status.value,
        'role_tag': task.roleTag,
        'context_tag': task.contextTag,
        'delegated_to': task.delegatedTo,
        'follow_up_date': task.followUpDate != null ? _formatDate(task.followUpDate!) : null,
        'is_repeatable': task.isRepeatable,
        'repeat_count': task.repeatCount,
        'repeat_days': task.repeatDays,
      }),
    ),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
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
        updates['follow_up_date'] = updates['followUpDate'];
      }
      updates.remove('followUpDate');
    }

    if (updates.containsKey('delegatedTo')) {
      updates['delegated_to'] = updates['delegatedTo'];
      updates.remove('delegatedTo');
    }

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

    final response = await _authenticatedRequest(
      (headers) => http.put(
        Uri.parse('$baseUrl/tasks/$id'),
        headers: headers,
        body: json.encode(updates),
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      return Task.fromJson(data['task']);
    } else {
      throw Exception('Falha ao atualizar tarefa: ${response.body}');
    }
  }





  Future<void> deleteTask(int taskId) async {
    final response = await _authenticatedRequest(
      (headers) => http.delete(
        Uri.parse('$baseUrl/tasks/$taskId'),
        headers: headers,
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao excluir tarefa');
    }
  }

  // ==================== STATS ====================

  Future<EnergyStats> getEnergyStats(DateTime startDate, DateTime endDate) async {
    final start = _formatDate(startDate);
    final end = _formatDate(endDate);
    
    final response = await _authenticatedRequest(
      (headers) => http.get(
        Uri.parse('$baseUrl/stats/energy?start_date=$start&end_date=$end'),
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      return EnergyStats.fromJson(json.decode(response.body));
    } else {
      throw Exception('Erro ao buscar estatísticas de energia');
    }
  }

  // ==================== CONFIG ====================

      Future<DailyConfig> setDailyConfig(DateTime date, double hours) async {
    final response = await _authenticatedRequest(
      (headers) => http.post(
        Uri.parse('$baseUrl/config/daily'),
        headers: headers,
        body: json.encode({
          'date': _formatDate(date),
          'available_hours': hours,
        }),
      ),
    );

    if (response.statusCode == 200) {
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
    
    final response = await _authenticatedRequest(
      (headers) => http.get(
        Uri.parse('$baseUrl/config/daily?date=$dateStr'),
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['available_hours'].toDouble();
    } else {
      return 8.0;
    }
  }


    // Toggle específico para tarefas repetíveis
  Future<void> toggleRepeatableTask(int taskId, DateTime date) async {
    final dateStr = _formatDate(date);
    
    final response = await _authenticatedRequest(
      (headers) => http.post(
        Uri.parse('$baseUrl/tasks/$taskId/toggle-date'),
        headers: headers,
        body: json.encode({'date': dateStr}),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar status repetível: ${response.body}');
    }
  }

  // ✅ Marcar tarefa como SKIPPED (ignorada) para uma data específica
  Future<void> skipTaskForDate(int taskId, DateTime date) async {
    final dateStr = _formatDate(date);
    
    final response = await _authenticatedRequest(
      (headers) => http.post(
        Uri.parse('$baseUrl/tasks/$taskId/skip'),
        headers: headers,
        body: json.encode({'date': dateStr}),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao ignorar tarefa: ${response.body}');
    }
  }


// ==================== DASHBOARD ====================

Future<Map<String, dynamic>> getDashboardStats(String period) async {
  if (period != 'week' && period != 'month') {
    throw Exception('Período deve ser "week" ou "month"');
  }

  final response = await _authenticatedRequest(
    (headers) => http.get(
      Uri.parse('$baseUrl/stats/dashboard?period=$period'),
      headers: headers,
    ),
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Erro ao buscar estatísticas do dashboard: ${response.body}');
  }
}

Future<Map<String, dynamic>> getTasksHistory({
  int page = 1,
  int perPage = 20,
  String? searchTerm,
}) async {
  final queryParams = {
    'page': page.toString(),
    'per_page': perPage.toString(),
  };

  if (searchTerm != null && searchTerm.isNotEmpty) {
    queryParams['search'] = searchTerm;
  }

  final uri = Uri.parse('$baseUrl/tasks/history').replace(queryParameters: queryParams);
  
  final response = await _authenticatedRequest(
    (headers) => http.get(uri, headers: headers),
  );

  if (response.statusCode == 200) {
    return json.decode(utf8.decode(response.bodyBytes));
  } else {
    throw Exception('Erro ao buscar histórico: ${response.body}');
  }
}


  // ==================== HELPERS ====================

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
