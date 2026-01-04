import 'package:flutter/foundation.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/models/daily_summary.dart';
import 'package:triade_app/services/api_service.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/models/dashboard_stats.dart';
import 'package:triade_app/models/history_task.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // LISTAS SEPARADAS
  List<Task> _dailyTasks = [];
  List<Task> _delegatedTasks = [];
  DailySummary? _summary;

  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();

  // Getters - DAILY VIEW
  List<Task> get tasks => _dailyTasks;
  DailySummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime get selectedDate => _selectedDate;

  // Getters - FOLLOW-UP
  List<Task> get delegatedTasks => _delegatedTasks;

  // Filtros para Daily View
  List<Task> get urgentTasks =>
      _dailyTasks.where((t) => t.triadCategory == TriadCategory.urgent).toList();

  List<Task> get importantTasks =>
      _dailyTasks.where((t) => t.triadCategory == TriadCategory.important).toList();

  List<Task> get circumstantialTasks =>
      _dailyTasks.where((t) => t.triadCategory == TriadCategory.circumstantial).toList();

  // ==================== DAILY TASKS ====================

  // ✅ Carregar tarefas do dia (Agora confia 100% na resposta da API)
  Future<void> loadDailyTasks(DateTime date) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedDate = date;
    notifyListeners();

    try {
      final result = await _apiService.getDailyTasks(date);

      // O backend já retorna o status correto (DONE ou ACTIVE) para repetíveis
      _dailyTasks = (result['tasks'] as List<Task>); 
      _summary = result['summary'];

      _recalculateSummary();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _dailyTasks = [];
      _summary = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Toggle de Tarefa Repetível (Chama API -> Atualiza Local)
    // ✅ Toggle de Tarefa Repetível (Chama API -> Atualiza Local)
  Future<void> toggleRepeatableDoneForDate(Task task, DateTime date) async {
    try {
      // 1. Persistir no backend
      await _apiService.toggleRepeatableTask(task.id, date);

      // 2. Atualizar localmente (Optimistic Update)
      final newStatus = task.status == TaskStatus.done 
          ? TaskStatus.active 
          : TaskStatus.done;

      // Atualiza na lista diária
      final index = _dailyTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _dailyTasks[index] = _dailyTasks[index].copyWith(status: newStatus);
      }

      // Atualiza na lista semanal (usando a correção do _isSameDay)
      for (int i = 0; i < _weeklyTasks.length; i++) {
        final t = _weeklyTasks[i];
        if (t.id == task.id && _isSameDay(t.dateScheduled, date)) {
          _weeklyTasks[i] = t.copyWith(status: newStatus);
        }
      }

      _recalculateSummary();
      notifyListeners();
    } catch (e) {
      _errorMessage = "Erro ao salvar status: $e";
      notifyListeners();
    }
  }


  // ==================== FOLLOW-UP ====================

  Future<void> loadDelegatedTasks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _delegatedTasks = await _apiService.getDelegatedTasks();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _delegatedTasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ==================== TAREFAS SEMANAIS ====================
  List<Task> _weeklyTasks = [];
  Map<String, double> _weeklyConfigs = {};
  DateTime? _weekStart;
  DateTime? _weekEnd;

  List<Task> get weeklyTasks => _weeklyTasks;
  Map<String, double> get weeklyConfigs => _weeklyConfigs;
  DateTime? get weekStart => _weekStart;
  DateTime? get weekEnd => _weekEnd;

  Future<void> loadWeeklyTasks(DateTime startDate, DateTime endDate) async {
  _isLoading = true;
  _errorMessage = null;
  _weekStart = startDate;
  _weekEnd = endDate;
  notifyListeners();

  try {
    // 1) Mantém configs vindo do endpoint semanal
    final weeklyResult = await _apiService.getWeeklyTasks(startDate, endDate);
    _weeklyConfigs = (weeklyResult['daily_configs'] as Map<String, double>?) ?? {};

    // 2) Busca tarefas dia-a-dia para garantir status correto das repetíveis
    final weekStartDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final days = List.generate(
      7,
      (i) => weekStartDateOnly.add(Duration(days: i)),
    );

    final dailyResults = await Future.wait(days.map(_apiService.getDailyTasks));

    final all = <Task>[];
    for (final res in dailyResults) {
      final tasks = (res['tasks'] as List<Task>)
          .where((t) {
            // 🔥 FILTRO CRÍTICO: Exclui tarefas delegadas E tarefas DONE com delegado
            final hasDelegated = t.delegatedTo != null && t.delegatedTo!.isNotEmpty;
            final isDone = t.status == TaskStatus.done;
            
            // Debug
            if (hasDelegated) {
              print('🟡 Filtrando task na Week View:');
              print('   - ID: ${t.id}');
              print('   - Title: ${t.title}');
              print('   - Status: ${t.status}');
              print('   - delegatedTo: ${t.delegatedTo}');
              print('   - Será excluída: ${t.status == TaskStatus.delegated || (isDone && hasDelegated)}');
            }
            
            // Regra: Exclui se for DELEGATED OU se for DONE com delegado
            if (t.status == TaskStatus.delegated) return false;
            if (isDone && hasDelegated) return false;
            
            return true;
          })
          .toList();
      all.addAll(tasks);
    }

    // 3) Dedupe defensivo
    final unique = <String, Task>{};
    for (final t in all) {
      final dayKey =
          '${t.dateScheduled.year}-${t.dateScheduled.month.toString().padLeft(2, '0')}-${t.dateScheduled.day.toString().padLeft(2, '0')}';
      unique['${t.id}_$dayKey'] = t;
    }

    _weeklyTasks = unique.values.toList();

    // 4) Ordena
    _weeklyTasks.sort((a, b) {
      final d = a.dateScheduled.compareTo(b.dateScheduled);
      if (d != 0) return d;
      return _triadOrder(a.triadCategory).compareTo(_triadOrder(b.triadCategory));
    });

    _errorMessage = null;
  } catch (e) {
    _errorMessage = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

  int _triadOrder(TriadCategory c) {
    switch (c) {
      case TriadCategory.urgent:
        return 0;
      case TriadCategory.important:
        return 1;
      case TriadCategory.circumstantial:
        return 2;
    }
  }

  // ==================== CRUD & AÇÕES ====================

  Future<bool> moveTaskToDate(int taskId, DateTime newDate) async {
    try {
      final updatedTask = await _apiService.moveTaskToDate(taskId, newDate);

      // Atualizar na lista semanal
      final index = _weeklyTasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _weeklyTasks[index] = updatedTask;
      }

      // Atualizar na lista diária se necessário
      final dailyIndex = _dailyTasks.indexWhere((t) => t.id == taskId);
      if (dailyIndex != -1) {
        final taskDate = DateTime(updatedTask.dateScheduled.year, updatedTask.dateScheduled.month, updatedTask.dateScheduled.day);
        final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

        if (!taskDate.isAtSameMomentAs(selectedDateOnly)) {
          _dailyTasks.removeAt(dailyIndex);
          _recalculateSummary();
        } else {
          _dailyTasks[dailyIndex] = updatedTask;
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  double getUsedHours(DateTime date) {
    final dayTasks = _weeklyTasks.where((t) {
      final taskDate = DateTime(t.dateScheduled.year, t.dateScheduled.month, t.dateScheduled.day);
      final checkDate = DateTime(date.year, date.month, date.day);
      return taskDate.isAtSameMomentAs(checkDate);
    }).toList();

    final totalMinutes = dayTasks.fold<int>(0, (sum, task) => sum + task.durationMinutes);
    return totalMinutes / 60.0;
  }

  bool canFitTask(DateTime targetDate, int durationMinutes) {
    final dateKey = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    final availableHours = _weeklyConfigs[dateKey] ?? 8.0;
    final usedHours = getUsedHours(targetDate);
    final taskHours = durationMinutes / 60.0;

    return (usedHours + taskHours) <= availableHours;
  }

  Future<bool> createTask(Task task) async {
    try {
      final newTask = await _apiService.createTask(task);

      if (newTask.status == TaskStatus.delegated) {
        _delegatedTasks.add(newTask);
      } else {
        _dailyTasks.add(newTask);
      }

      await loadDailyTasks(_selectedDate);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(int taskId, Map<String, dynamic> updates) async {
    try {
      // Acha a task atual em memória
      Task? existing;
      for (final t in _dailyTasks) {
        if (t.id == taskId) { existing = t; break; }
      }
      if (existing == null) {
        for (final t in _weeklyTasks) {
          if (t.id == taskId) { existing = t; break; }
        }
      }
      if (existing == null) {
        for (final t in _delegatedTasks) {
          if (t.id == taskId) { existing = t; break; }
        }
      }

      final isRepeatable = existing?.isRepeatable ?? false;

      // ✅ Repetível: nunca enviar campos que “resetam” a série no backend
      if (isRepeatable) {
        final u = Map<String, dynamic>.from(updates);
        u.remove('date_scheduled');
        u.remove('is_repeatable');
        u.remove('repeat_count');
        updates = u;
      }

      if (updates.isEmpty) {
        notifyListeners();
        return true;
      }

      final updatedFromApi = await _apiService.updateTask(taskId, updates);

      // Função auxiliar para atualizar listas
            void updateList(List<Task> list) {
        for (int i = 0; i < list.length; i++) {
          if (list[i].id == taskId) {
            // ✅ CORREÇÃO: Recriação manual para aceitar NULL em delegatedTo
            list[i] = Task(
              id: list[i].id,
              title: updatedFromApi.title,
              triadCategory: updatedFromApi.triadCategory,
              durationMinutes: updatedFromApi.durationMinutes,
              status: updatedFromApi.status,
              dateScheduled: updatedFromApi.dateScheduled,
              roleTag: updatedFromApi.roleTag,
              contextTag: updatedFromApi.contextTag,
              // O segredo: pega o valor direto da API (mesmo que seja null)
              delegatedTo: updatedFromApi.delegatedTo,
              followUpDate: updatedFromApi.followUpDate,
              isRepeatable: updatedFromApi.isRepeatable,
              repeatCount: updatedFromApi.repeatCount,
              repeatDays: updatedFromApi.repeatDays,
              createdAt: updatedFromApi.createdAt,
              updatedAt: updatedFromApi.updatedAt,
            );
          }
        }
      }


      updateList(_dailyTasks);
      updateList(_weeklyTasks);

      // Atualiza lista de delegadas
            // ✅ CORREÇÃO 3 (Parte A): Gerenciamento da lista de delegadas
      final delegatedIndex = _delegatedTasks.indexWhere((t) => t.id == taskId);
      if (delegatedIndex != -1) {
        // Se o retorno da API diz que não tem mais delegado (foi reassumida)
        if (updatedFromApi.delegatedTo == null || updatedFromApi.delegatedTo!.isEmpty) {
          // 1. Remove da lista de Follow-up imediatamente
          _delegatedTasks.removeAt(delegatedIndex);

          // 2. Se a tarefa reassumida for para o dia selecionado, adiciona na Daily View
          if (_isSameDay(updatedFromApi.dateScheduled, _selectedDate)) {
             // Evita duplicidade visual
             if (!_dailyTasks.any((t) => t.id == updatedFromApi.id)) {
                _dailyTasks.add(updatedFromApi);
                // Reordena para manter consistência visual
                _dailyTasks.sort((a, b) => _triadOrder(a.triadCategory).compareTo(_triadOrder(b.triadCategory)));
             }
          }
        } else {
          // Apenas atualiza os dados mantendo na lista
          _delegatedTasks[delegatedIndex] = updatedFromApi;
        }
      }


      _recalculateSummary();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ✅ Recalcular summary localmente
  void _recalculateSummary() {
    if (_summary == null) return;

    // CORREÇÃO: Filtrar tarefas delegadas para não somar no tempo usado
    final tasksToCount = _dailyTasks.where((t) => 
        (t.delegatedTo == null || t.delegatedTo!.isEmpty)
    );

    final totalMinutes = tasksToCount.fold<int>(0, (sum, t) => sum + t.durationMinutes);
    final usedHours = totalMinutes / 60.0;

    _summary = DailySummary(
      date: _summary!.date,
      availableHours: _summary!.availableHours,
      usedHours: usedHours,
      totalTasks: _dailyTasks.where((t) => t.status == TaskStatus.active).length,
      remainingHours: (_summary!.availableHours - usedHours).clamp(0.0, double.infinity),
    );
  }

    // ✅ CORREÇÃO FINAL: Resolve o Checkbox Normal e a Repetível do Dia
  Future<bool> toggleTaskDone(int taskId) async {
    // 1. Localizar a tarefa nas listas (Daily ou Weekly)
    Task? task;
    bool isDaily = true;
    int index = _dailyTasks.indexWhere((t) => t.id == taskId);

    if (index != -1) {
      task = _dailyTasks[index];
    } else {
      index = _weeklyTasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        task = _weeklyTasks[index];
        isDaily = false;
      }
    }

    if (task == null) return false;

    // 2. Calcular o novo status
    final newStatusEnum = task.status == TaskStatus.done ? TaskStatus.active : TaskStatus.done;

    // 3. ATUALIZAÇÃO OTIMISTA (Isso faz o check aparecer instantaneamente para tarefas normais)
    final updatedTask = task.copyWith(status: newStatusEnum);

    if (isDaily) {
      _dailyTasks[index] = updatedTask;
    } else {
      _weeklyTasks[index] = updatedTask;
    }

    _recalculateSummary();
    notifyListeners(); // ⚡ Atualiza a tela imediatamente

    // 4. Envio Inteligente para o Backend
    try {
      if (task.isRepeatable) {
        // ✅ O PULO DO GATO: Se for repetível (mesmo sendo hoje), usa o endpoint de toggle-date
        // Isso garante que o backend crie a exceção para este dia específico
        await _apiService.toggleRepeatableTask(taskId, task.dateScheduled);
      } else {
        // Tarefa normal usa o update padrão
        final newStatusString = newStatusEnum == TaskStatus.done ? 'DONE' : 'ACTIVE';
        await _apiService.updateTask(taskId, {'status': newStatusString});
      }
      return true;
    } catch (e) {
      // Se der erro, reverte visualmente (opcional)
      _errorMessage = "Erro ao sincronizar: $e";
      notifyListeners();
      return false;
    }
  }




  // ✅ Excluir tarefa
  Future<bool> deleteTask(int taskId) async {
    try {
      await _apiService.deleteTask(taskId);

      _dailyTasks.removeWhere((t) => t.id == taskId);
      _delegatedTasks.removeWhere((t) => t.id == taskId);
      _weeklyTasks.removeWhere((t) => t.id == taskId);

      _recalculateSummary();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<Task>> getPendingReview(DateTime date) async {
    try {
      return await _apiService.getPendingReview(date);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }



  // ==================== DASHBOARD ====================

DashboardStats? _dashboardStats;
String _currentPeriod = 'week';

DashboardStats? get dashboardStats => _dashboardStats;
String get currentPeriod => _currentPeriod;

Future<void> loadDashboardStats(String period) async {
  _isLoading = true;
  _errorMessage = null;
  _currentPeriod = period;
  notifyListeners();

  try {
    final data = await _apiService.getDashboardStats(period);
    _dashboardStats = DashboardStats.fromJson(data);
    _errorMessage = null;
  } catch (e) {
    _errorMessage = e.toString();
    _dashboardStats = null;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

// ==================== HISTÓRICO ====================

List<HistoryTask> _historyTasks = [];
int _currentHistoryPage = 1;
bool _hasMoreHistory = true;
String? _historySearchTerm;

List<HistoryTask> get historyTasks => _historyTasks;
bool get hasMoreHistory => _hasMoreHistory;
String? get historySearchTerm => _historySearchTerm;

Future<void> loadHistory({bool loadMore = false, String? searchTerm}) async {
  // Se for nova busca, reseta a lista
  if (!loadMore || searchTerm != _historySearchTerm) {
    _historyTasks = [];
    _currentHistoryPage = 1;
    _hasMoreHistory = true;
    _historySearchTerm = searchTerm;
  }

  if (!_hasMoreHistory) return;

  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final data = await _apiService.getTasksHistory(
      page: _currentHistoryPage,
      perPage: 20,
      searchTerm: searchTerm,
    );

    final tasks = (data['tasks'] as List)
        .map((json) => HistoryTask.fromJson(json))
        .toList();

    _historyTasks.addAll(tasks);

    final pagination = data['pagination'];
    _hasMoreHistory = pagination['has_next'];
    _currentHistoryPage++;

    _errorMessage = null;
  } catch (e) {
    _errorMessage = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

void clearHistorySearch() {
  _historySearchTerm = null;
  _historyTasks = [];
  _currentHistoryPage = 1;
  _hasMoreHistory = true;
  notifyListeners();
}



  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }


  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
