import 'package:flutter/foundation.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/models/daily_summary.dart';
import 'package:triade_app/services/api_service.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/models/dashboard_stats.dart';
import 'package:triade_app/models/history_task.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

    // ✅ NOVO: Cache de dados por data
  final Map<String, List<Task>> _dailyTasksCache = {};
  final Map<String, DailySummary> _dailySummaryCache = {};
  final Map<String, List<Task>> _weeklyTasksCache = {};
  final Map<String, Map<String, double>> _weeklyConfigsCache = {};
  final Map<String, List<Task>> _delegatedTasksCache = {};

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
  List<Task> get highEnergyTasks =>
      _dailyTasks.where((t) => t.energyLevel == EnergyLevel.highEnergy).toList();

  List<Task> get renewalTasks =>
      _dailyTasks.where((t) => t.energyLevel == EnergyLevel.renewal).toList();

  List<Task> get lowEnergyTasks =>
      _dailyTasks.where((t) => t.energyLevel == EnergyLevel.lowEnergy).toList();

  // ==================== DAILY TASKS (VERSÃO COM CACHE) ====================

  Future<void> loadDailyTasks(DateTime date) async {
  final dateKey = _dateKey(date);
  
  // Mostra cache se existir
  if (_dailyTasksCache.containsKey(dateKey)) {
    _dailyTasks = _dailyTasksCache[dateKey]!;
    _summary = _dailySummaryCache[dateKey];
    _selectedDate = date;
    notifyListeners();
  }

  _isLoading = true;
  _errorMessage = null;
  _selectedDate = date;
  
  if (!_dailyTasksCache.containsKey(dateKey)) {
    notifyListeners(); // Só notifica se não tem cache
  }

  try {
    final result = await _apiService.getDailyTasks(date);
    final newTasks = result['tasks'] as List<Task>;
    final newSummary = result['summary'] as DailySummary;

    // Atualiza cache SEMPRE
    _dailyTasksCache[dateKey] = newTasks;
    _dailySummaryCache[dateKey] = newSummary;

    // Atualiza variáveis atuais
    _dailyTasks = newTasks;
    _summary = newSummary;

    _recalculateSummary();
    _errorMessage = null;
  } catch (e) {
    _errorMessage = e.toString();
    
    if (!_dailyTasksCache.containsKey(dateKey)) {
      _dailyTasks = [];
      _summary = null;
    }
  } finally {
    // ✅ CRÍTICO: SEMPRE desliga loading
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
  const cacheKey = 'delegated_all';
  
  if (_delegatedTasksCache.containsKey(cacheKey)) {
    _delegatedTasks = _delegatedTasksCache[cacheKey]!;
    notifyListeners();
  }

  _isLoading = true;
  _errorMessage = null;
  
  if (!_delegatedTasksCache.containsKey(cacheKey)) {
    notifyListeners();
  }

  try {
    final newTasks = await _apiService.getDelegatedTasks();
    
    _delegatedTasksCache[cacheKey] = newTasks;
    _delegatedTasks = newTasks;
    _errorMessage = null;
  } catch (e) {
    _errorMessage = e.toString();
    if (!_delegatedTasksCache.containsKey(cacheKey)) {
      _delegatedTasks = [];
    }
  } finally {
    // ✅ CRÍTICO: SEMPRE desliga loading
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

  // ==================== WEEKLY TASKS (VERSÃO COM CACHE) ====================

  Future<void> loadWeeklyTasks(DateTime startDate, DateTime endDate) async {
  final weekKey = '${_dateKey(startDate)}_${_dateKey(endDate)}';
  
  if (_weeklyTasksCache.containsKey(weekKey)) {
    _weeklyTasks = _weeklyTasksCache[weekKey]!;
    _weeklyConfigs = _weeklyConfigsCache[weekKey]!;
    _weekStart = startDate;
    _weekEnd = endDate;
    notifyListeners();
  }

  _isLoading = true;
  _errorMessage = null;
  _weekStart = startDate;
  _weekEnd = endDate;
  
  if (!_weeklyTasksCache.containsKey(weekKey)) {
    notifyListeners();
  }

  try {
    final weeklyResult = await _apiService.getWeeklyTasks(startDate, endDate);
    _weeklyConfigs = (weeklyResult['daily_configs'] as Map<String, double>?) ?? {};

    final weekStartDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final days = List.generate(7, (i) => weekStartDateOnly.add(Duration(days: i)));

    final dailyResults = await Future.wait(days.map(_apiService.getDailyTasks));

    final all = <Task>[];
    for (final res in dailyResults) {
      final tasks = (res['tasks'] as List<Task>)
          .where((t) {
            final hasDelegated = t.delegatedTo != null && t.delegatedTo!.isNotEmpty;
            if (hasDelegated) return false;
            if (t.status == TaskStatus.delegated) return false;
            return true;
          })
          .toList();
      all.addAll(tasks);
    }

    final unique = <String, Task>{};
    for (final t in all) {
      final dayKey = '${t.dateScheduled.year}-${t.dateScheduled.month.toString().padLeft(2, '0')}-${t.dateScheduled.day.toString().padLeft(2, '0')}';
      unique['${t.id}_$dayKey'] = t;
    }

    _weeklyTasks = unique.values.toList();

    // Ordenação completa
    _weeklyTasks.sort((a, b) {
      final catComp = _energyLevelOrder(a.energyLevel).compareTo(_energyLevelOrder(b.energyLevel));
      if (catComp != 0) return catComp;
      
      final aContext = a.contextTag ?? 'zzz';
      final bContext = b.contextTag ?? 'zzz';
      final contextComp = aContext.compareTo(bContext);
      if (contextComp != 0) return contextComp;
      
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    // Atualiza cache SEMPRE
    _weeklyTasksCache[weekKey] = _weeklyTasks;
    _weeklyConfigsCache[weekKey] = _weeklyConfigs;

    _errorMessage = null;
  } catch (e) {
    _errorMessage = e.toString();
    
    if (!_weeklyTasksCache.containsKey(weekKey)) {
      _weeklyTasks = [];
      _weeklyConfigs = {};
    }
  } finally {
    // ✅ CRÍTICO: SEMPRE desliga loading
    _isLoading = false;
    notifyListeners();
  }
}


  // ✅ NOVO: Helper para gerar chave de cache
  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // ✅ NOVO: Limpar cache antigo (opcional, para não crescer infinito)
  void clearOldCache() {
    final now = DateTime.now();
    final cutoffDate = now.subtract(const Duration(days: 30));
    
    _dailyTasksCache.removeWhere((key, _) {
      final parts = key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return date.isBefore(cutoffDate);
    });
    
    _dailySummaryCache.removeWhere((key, _) {
      final parts = key.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      return date.isBefore(cutoffDate);
    });
  }



  int _energyLevelOrder(EnergyLevel e) {
    switch (e) {
      case EnergyLevel.highEnergy:
        return 0;
      case EnergyLevel.renewal:
        return 1;
      case EnergyLevel.lowEnergy:
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

    // ✅ CORREÇÃO: Invalida caches relacionados
    if (updates.containsKey('delegatedTo') || updates.containsKey('delegated_to')) {
      _delegatedTasksCache.clear(); // Força reload em Follow-up
      _dailyTasksCache.clear(); // Força recálculo do summary na Daily
      _weeklyTasksCache.clear(); // Força atualização na Weekly
    }

    void updateList(List<Task> list) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == taskId) {
          list[i] = Task(
            id: list[i].id,
            title: updatedFromApi.title,
            energyLevel: updatedFromApi.energyLevel,
            durationMinutes: updatedFromApi.durationMinutes,
            status: updatedFromApi.status,
            dateScheduled: updatedFromApi.dateScheduled,
            roleTag: updatedFromApi.roleTag,
            contextTag: updatedFromApi.contextTag,
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

    final delegatedIndex = _delegatedTasks.indexWhere((t) => t.id == taskId);
    if (delegatedIndex != -1) {
      if (updatedFromApi.delegatedTo == null || updatedFromApi.delegatedTo!.isEmpty) {
        _delegatedTasks.removeAt(delegatedIndex);

        if (_isSameDay(updatedFromApi.dateScheduled, _selectedDate)) {
          if (!_dailyTasks.any((t) => t.id == updatedFromApi.id)) {
            _dailyTasks.add(updatedFromApi);
            _dailyTasks.sort((a, b) => _energyLevelOrder(a.energyLevel).compareTo(_energyLevelOrder(b.energyLevel)));
          }
        }
      } else {
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


  Future<bool> toggleTaskDone(int taskId) async {
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

  final newStatusEnum = task.status == TaskStatus.done ? TaskStatus.active : TaskStatus.done;
  final updatedTask = task.copyWith(status: newStatusEnum);
  final isDelegated = updatedTask.delegatedTo != null && updatedTask.delegatedTo!.isNotEmpty;

  if (isDaily) {
    _dailyTasks[index] = updatedTask;
  } else {
    if (isDelegated && newStatusEnum == TaskStatus.active) {
      _weeklyTasks.removeAt(index);
    } else {
      _weeklyTasks[index] = updatedTask;
    }
  }

  _recalculateSummary();
  notifyListeners();

  try {
    if (task.isRepeatable) {
      await _apiService.toggleRepeatableTask(taskId, task.dateScheduled);
    } else {
      final newStatusString = newStatusEnum == TaskStatus.done ? 'DONE' : 'ACTIVE';
      await _apiService.updateTask(taskId, {'status': newStatusString});
    }
    
    // ✅ NOVO: Invalida cache da weekly para sincronizar
    _weeklyTasksCache.clear();
    
    return true;
  } catch (e) {
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

    // 🔥 CORREÇÃO: Remove duplicatas usando chave única (id + data + hora)
    final existingKeys = _historyTasks.map((t) => 
      '${t.id}_${t.dateScheduled.toIso8601String()}_${t.completedAt.toIso8601String()}'
    ).toSet();

    final newTasks = tasks.where((task) {
      final key = '${task.id}_${task.dateScheduled.toIso8601String()}_${task.completedAt.toIso8601String()}';
      return !existingKeys.contains(key);
    }).toList();

    _historyTasks.addAll(newTasks);

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


