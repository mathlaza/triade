import 'package:flutter/foundation.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/models/daily_summary.dart';
import 'package:triade_app/services/api_service.dart';
import 'package:triade_app/config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';


class TaskProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // LISTAS SEPARADAS
  List<Task> _dailyTasks = [];
  List<Task> _delegatedTasks = [];
  DailySummary? _summary;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _selectedDate = DateTime.now();


    // ==================== REPEATABLE DONE (por dia) - LOCAL ====================
  final Set<String> _repeatableDoneKeys = <String>{};
  bool _repeatableDoneLoaded = false;

  String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _repeatableKey(int taskId, DateTime d) => '${taskId}_${_dayKey(d)}';

  Future<void> _ensureRepeatableDoneLoaded() async {
    if (_repeatableDoneLoaded) return;
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('repeatable_done_keys') ?? <String>[];
    _repeatableDoneKeys
      ..clear()
      ..addAll(list);
    _repeatableDoneLoaded = true;
  }

  Future<void> _persistRepeatableDoneKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('repeatable_done_keys', _repeatableDoneKeys.toList());
  }

  Task _applyRepeatableDoneOverride(Task t) {
    if (!t.isRepeatable) return t;

    final key = _repeatableKey(t.id, t.dateScheduled);
    final shouldBeDone = _repeatableDoneKeys.contains(key);
    final desiredStatus = shouldBeDone ? TaskStatus.done : TaskStatus.active;

    if (t.status == desiredStatus) return t;
    return t.copyWith(status: desiredStatus);
  }

  void _applyRepeatableOverrideToInMemoryLists() {
    _dailyTasks = _dailyTasks.map(_applyRepeatableDoneOverride).toList();
    _weeklyTasks = _weeklyTasks.map(_applyRepeatableDoneOverride).toList();
  }

  Future<void> toggleRepeatableDoneForDate(Task task, DateTime date) async {
    await _ensureRepeatableDoneLoaded();

    final dateOnly = DateTime(date.year, date.month, date.day);
    final key = _repeatableKey(task.id, dateOnly);

    if (_repeatableDoneKeys.contains(key)) {
      _repeatableDoneKeys.remove(key);
    } else {
      _repeatableDoneKeys.add(key);
    }

    await _persistRepeatableDoneKeys();

    _applyRepeatableOverrideToInMemoryLists();
    _recalculateSummary();
    notifyListeners();
  }


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

  // ✅ Carregar tarefas do dia (ACTIVE + DONE)
  Future<void> loadDailyTasks(DateTime date) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedDate = date;
    notifyListeners();

    try {
      await _ensureRepeatableDoneLoaded();

      final result = await _apiService.getDailyTasks(date);
      final tasks = (result['tasks'] as List<Task>);

      _dailyTasks = tasks.map(_applyRepeatableDoneOverride).toList();
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


  // Carregar tarefas delegadas (Follow-up)
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

  // Carregar tarefas da semana
  // Carregar tarefas da semana
Future<void> loadWeeklyTasks(DateTime startDate, DateTime endDate) async {
  _isLoading = true;
  _errorMessage = null;
  _weekStart = startDate;
  _weekEnd = endDate;
  notifyListeners();

    try {
    await _ensureRepeatableDoneLoaded();

    // 1) Mantém configs vindo do endpoint semanal (seu app já usa isso)
    final weeklyResult = await _apiService.getWeeklyTasks(startDate, endDate);
    _weeklyConfigs = (weeklyResult['daily_configs'] as Map<String, double>?) ?? {};

    // 2) Busca tarefas dia-a-dia (isso garante que repetíveis apareçam na semana)
    final weekStartDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final days = List.generate(
      7,
      (i) => weekStartDateOnly.add(Duration(days: i)),
    );

    final dailyResults = await Future.wait(days.map(_apiService.getDailyTasks));

    final all = <Task>[];
    for (final res in dailyResults) {
      final tasks = (res['tasks'] as List<Task>)
          .where((t) => t.status != TaskStatus.delegated)
          .map(_applyRepeatableDoneOverride)
          .toList();
      all.addAll(tasks);
    }

    // 3) Dedupe defensivo (caso API retorne algo duplicado)
    final unique = <String, Task>{};
    for (final t in all) {
      final dayKey =
          '${t.dateScheduled.year}-${t.dateScheduled.month.toString().padLeft(2, '0')}-${t.dateScheduled.day.toString().padLeft(2, '0')}';
      unique['${t.id}_$dayKey'] = t;
    }

    _weeklyTasks = unique.values.toList();

    // 4) Ordena: por dia e por categoria (Urgente -> Importante -> Circunstancial)
    _weeklyTasks.sort((a, b) {
      final d = a.dateScheduled.compareTo(b.dateScheduled);
      if (d != 0) return d;
      return _triadOrder(a.triadCategory).compareTo(_triadOrder(b.triadCategory));
    });

    _errorMessage = null;
  }
 catch (e) {
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


  // Mover tarefa para outro dia (Drag & Drop)
  Future<bool> moveTaskToDate(int taskId, DateTime newDate) async {
    try {
      final updatedTask = await _apiService.moveTaskToDate(taskId, newDate);

      // Atualizar na lista semanal
      final index = _weeklyTasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _weeklyTasks[index] = updatedTask;
      }

      // ✅ Atualizar também na lista diária se estiver visível
      final dailyIndex = _dailyTasks.indexWhere((t) => t.id == taskId);
      if (dailyIndex != -1) {
        final taskDate = DateTime(updatedTask.dateScheduled.year, updatedTask.dateScheduled.month, updatedTask.dateScheduled.day);
        final selectedDateOnly = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

        if (!taskDate.isAtSameMomentAs(selectedDateOnly)) {
          _dailyTasks.removeAt(dailyIndex);
          _recalculateSummary(); // ✅ Recalcular summary após remover
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

  // Calcular horas usadas em um dia específico
  double getUsedHours(DateTime date) {
    final dayTasks = _weeklyTasks.where((t) {
      final taskDate = DateTime(t.dateScheduled.year, t.dateScheduled.month, t.dateScheduled.day);
      final checkDate = DateTime(date.year, date.month, date.day);
      return taskDate.isAtSameMomentAs(checkDate);
    }).toList();

    final totalMinutes = dayTasks.fold<int>(0, (sum, task) => sum + task.durationMinutes);
    return totalMinutes / 60.0;
  }

  // Verificar se dia comporta tarefa
  bool canFitTask(DateTime targetDate, int durationMinutes) {
    final dateKey = '${targetDate.year}-${targetDate.month.toString().padLeft(2, '0')}-${targetDate.day.toString().padLeft(2, '0')}';
    final availableHours = _weeklyConfigs[dateKey] ?? 8.0;
    final usedHours = getUsedHours(targetDate);
    final taskHours = durationMinutes / 60.0;

    return (usedHours + taskHours) <= availableHours;
  }

  // Criar tarefa
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

  // ✅ Atualizar tarefa (COM RECÁLCULO DE SUMMARY)
  Future<bool> updateTask(int taskId, Map<String, dynamic> updates) async {
  try {
    // acha a task atual em memória (pra saber se é repetível)
    Task? existing;
    for (final t in _dailyTasks) {
      if (t.id == taskId) {
        existing = t;
        break;
      }
    }
    if (existing == null) {
      for (final t in _weeklyTasks) {
        if (t.id == taskId) {
          existing = t;
          break;
        }
      }
    }
    if (existing == null) {
      for (final t in _delegatedTasks) {
        if (t.id == taskId) {
          existing = t;
          break;
        }
      }
    }

    final isRepeatable = existing?.isRepeatable ?? false;

    // ✅ repetível: nunca enviar campos que “resetam” a série no backend
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

    if (isRepeatable) {
      // ✅ repetível: atualiza os campos, mas mantém dateScheduled de cada ocorrência
      Task merge(Task t) {
        final merged = t.copyWith(
          title: updatedFromApi.title,
          triadCategory: updatedFromApi.triadCategory,
          durationMinutes: updatedFromApi.durationMinutes,
          roleTag: updatedFromApi.roleTag,
          contextTag: updatedFromApi.contextTag,
          delegatedTo: updatedFromApi.delegatedTo,
          followUpDate: updatedFromApi.followUpDate,
          status: updatedFromApi.status,
          repeatCount: updatedFromApi.repeatCount,
          updatedAt: updatedFromApi.updatedAt,
          isRepeatable: true,
        );
        return _applyRepeatableDoneOverride(merged);
      }

      _dailyTasks = _dailyTasks.map((t) => t.id == taskId ? merge(t) : _applyRepeatableDoneOverride(t)).toList();
      _weeklyTasks = _weeklyTasks.map((t) => t.id == taskId ? merge(t) : _applyRepeatableDoneOverride(t)).toList();
      _delegatedTasks = _delegatedTasks.map((t) => t.id == taskId ? merge(t) : t).toList();
    } else {
      final updatedTask = _applyRepeatableDoneOverride(updatedFromApi);

      final dailyIndex = _dailyTasks.indexWhere((t) => t.id == taskId);
      if (dailyIndex != -1) {
        _dailyTasks[dailyIndex] = updatedTask;
      }

      final delegatedIndex = _delegatedTasks.indexWhere((t) => t.id == taskId);
      if (delegatedIndex != -1) {
        _delegatedTasks[delegatedIndex] = updatedTask;
      }

      for (int i = 0; i < _weeklyTasks.length; i++) {
        if (_weeklyTasks[i].id == taskId) {
          _weeklyTasks[i] = updatedTask;
        }
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


  // ✅ MÉTODO NOVO: Recalcular summary localmente (SEM chamar backend)
  void _recalculateSummary() {
    if (_summary == null) return;

    // Contar TODAS as tarefas (ACTIVE + DONE), como você pediu
    final totalMinutes = _dailyTasks.fold<int>(0, (sum, t) => sum + t.durationMinutes);
    final usedHours = totalMinutes / 60.0;

    _summary = DailySummary(
      date: _summary!.date,
      availableHours: _summary!.availableHours,
      usedHours: usedHours,
      totalTasks: _dailyTasks.where((t) => t.status == TaskStatus.active).length,
      remainingHours: (_summary!.availableHours - usedHours).clamp(0.0, double.infinity),
    );
  }

  // Marcar como concluída
  Future<bool> toggleTaskDone(int taskId) async {
    return await updateTask(taskId, {'status': 'DONE'});
  }

  // ✅ Excluir tarefa (COM RECÁLCULO DE SUMMARY)
  // ✅ Excluir tarefa (COM RECÁLCULO DE SUMMARY)
  Future<bool> deleteTask(int taskId) async {
    try {
      await _apiService.deleteTask(taskId);

      // Remover de todas as listas
      _dailyTasks.removeWhere((t) => t.id == taskId);
      _delegatedTasks.removeWhere((t) => t.id == taskId);
      _weeklyTasks.removeWhere((t) => t.id == taskId);

      // Remove marcações locais de repeatable DONE desse taskId
      await _ensureRepeatableDoneLoaded();
      _repeatableDoneKeys.removeWhere((k) => k.startsWith('${taskId}_'));
      await _persistRepeatableDoneKeys();

      _recalculateSummary();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }



  // Buscar tarefas pendentes de revisão
  Future<List<Task>> getPendingReview(DateTime date) async {
    try {
      return await _apiService.getPendingReview(date);
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Limpar erro
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
