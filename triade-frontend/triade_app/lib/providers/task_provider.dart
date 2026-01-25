import 'package:flutter/foundation.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/models/daily_summary.dart';
import 'package:triade_app/services/api_service.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/models/dashboard_stats.dart';
import 'package:triade_app/models/history_task.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // ✅ Cache de dados por data
  final Map<String, List<Task>> _dailyTasksCache = {};
  final Map<String, DailySummary> _dailySummaryCache = {};
  final Map<String, List<Task>> _weeklyTasksCache = {};
  final Map<String, Map<String, double>> _weeklyConfigsCache = {};
  final Map<String, List<Task>> _delegatedTasksCache = {};

  // 🔥 NOVO: Flag para bloquear revalidações durante operações
  bool _isOperationInProgress = false;
  
  // 🔥 NOVO: Timestamp da última modificação local (para ignorar dados antigos da API)
  DateTime _lastLocalModification = DateTime.now();

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

  // Filtros para Daily View (COM ORDENAÇÃO POR HORÁRIO)
  List<Task> get highEnergyTasks => _sortTasksByScheduledTime(
      _dailyTasks.where((t) => t.energyLevel == EnergyLevel.highEnergy).toList());

  List<Task> get renewalTasks => _sortTasksByScheduledTime(
      _dailyTasks.where((t) => t.energyLevel == EnergyLevel.renewal).toList());

  List<Task> get lowEnergyTasks => _sortTasksByScheduledTime(
      _dailyTasks.where((t) => t.energyLevel == EnergyLevel.lowEnergy).toList());

  /// Ordena tarefas: horário agendado (mais cedo primeiro), depois sem horário, depois por contexto
  List<Task> _sortTasksByScheduledTime(List<Task> tasks) {
    tasks.sort((a, b) {
      // 1. Primeiro: tarefas com horário vs sem horário
      final aHasTime = a.scheduledTime != null;
      final bHasTime = b.scheduledTime != null;

      if (aHasTime && !bHasTime) return -1; // a tem horário, b não -> a vem primeiro
      if (!aHasTime && bHasTime) return 1;  // b tem horário, a não -> b vem primeiro

      // 2. Se ambas têm horário, ordena por horário (mais cedo primeiro)
      if (aHasTime && bHasTime) {
        final comparison = a.scheduledTime!.compareTo(b.scheduledTime!);
        if (comparison != 0) return comparison;
      }

      // 3. Se empate ou ambas sem horário, ordena por contexto
      final aContext = a.contextTag ?? '';
      final bContext = b.contextTag ?? '';
      return aContext.compareTo(bContext);
    });
    return tasks;
  }


  // ✅ NOVO: Getters eficientes para horas completadas por categoria
  double get highEnergyCompletedHours => _dailyTasks
      .where((t) => t.energyLevel == EnergyLevel.highEnergy && t.status == TaskStatus.done)
      .fold(0.0, (sum, t) => sum + (t.durationMinutes / 60));

  double get renewalCompletedHours => _dailyTasks
      .where((t) => t.energyLevel == EnergyLevel.renewal && t.status == TaskStatus.done)
      .fold(0.0, (sum, t) => sum + (t.durationMinutes / 60));

  double get lowEnergyCompletedHours => _dailyTasks
      .where((t) => t.energyLevel == EnergyLevel.lowEnergy && t.status == TaskStatus.done)
      .fold(0.0, (sum, t) => sum + (t.durationMinutes / 60));

  // ==================== DAILY TASKS (VERSÃO COM CACHE) ====================

  Future<void> loadDailyTasks(DateTime date) async {
  final dateKey = _dateKey(date);
  _selectedDate = date;
  
  // ✅ Se tem cache, usa IMEDIATAMENTE e NÃO mostra loading
  if (_dailyTasksCache.containsKey(dateKey)) {
    _dailyTasks = _dailyTasksCache[dateKey]!;
    _summary = _dailySummaryCache[dateKey];
    _isLoading = false;
    _errorMessage = null;
  
    notifyListeners();
    
    // ✅ Revalida em background (silent refresh)
    _revalidateDailyTasks(date, dateKey);
    return;
  }

  
  // ✅ Sem cache: mostra loading
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final result = await _apiService.getDailyTasks(date);
    final newTasks = result['tasks'] as List<Task>;
    final newSummary = result['summary'] as DailySummary;
    
    // ✅ CRÍTICO: Validar que as tarefas são realmente do dia solicitado
    for (var task in newTasks) {
      final taskDateKey = _dateKey(task.dateScheduled);
      if (taskDateKey != dateKey) {
      }
    }

    _dailyTasksCache[dateKey] = newTasks;
    _dailySummaryCache[dateKey] = newSummary;
    _dailyTasks = newTasks;
    _summary = newSummary;
    
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

// ✅ NOVO: Revalida cache em background (COM PROTEÇÃO CONTRA FLIP-FLOP)
Future<void> _revalidateDailyTasks(DateTime date, String dateKey) async {
  // 🔥 CRÍTICO: Captura o timestamp ANTES de chamar a API
  final revalidationStartTime = DateTime.now();
  
  try {
    // 🔥 NÃO revalida se há operação em andamento
    if (_isOperationInProgress) {
      return;
    }
    
    final result = await _apiService.getDailyTasks(date);
    
    // 🔥 CRÍTICO: Ignora dados da API se houve modificação LOCAL mais recente
    // Isso evita o flip-flop onde dados antigos da API sobrescrevem updates otimistas
    if (_lastLocalModification.isAfter(revalidationStartTime)) {
      return;
    }
    
    // 🔥 CRÍTICO: Verifica novamente após a chamada async
    if (_isOperationInProgress) {
      return;
    }
    
    final newTasks = result['tasks'] as List<Task>;
    final newSummary = result['summary'] as DailySummary;

    // ✅ Atualiza cache silenciosamente
    _dailyTasksCache[dateKey] = newTasks;
    _dailySummaryCache[dateKey] = newSummary;
    
    // ✅ Se ainda estiver na mesma data, atualiza a tela
    if (_dateKey(_selectedDate) == dateKey) {
      _dailyTasks = newTasks;
      _summary = newSummary;
      _recalculateSummary();
      notifyListeners();
    }
  } catch (e) {
    // ✅ Falha silenciosa: mantém cache antigo
  }
}

  // ✅ Toggle de Tarefa Repetível (COM PROTEÇÃO CONTRA FLIP-FLOP)
  Future<void> toggleRepeatableDoneForDate(Task task, DateTime date) async {
    // 🔥 CRÍTICO: Marca que uma operação está em andamento
    _isOperationInProgress = true;
    _lastLocalModification = DateTime.now();
    
    // 1. 🔥 OPTIMISTIC UPDATE - Atualiza localmente PRIMEIRO (UI instantânea)
    final newStatus = task.status == TaskStatus.done 
        ? TaskStatus.active 
        : TaskStatus.done;

    // Guarda estado original para rollback
    final originalDailyTasks = List<Task>.from(_dailyTasks);
    final originalWeeklyTasks = List<Task>.from(_weeklyTasks);

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
    
    // 🔥 CRÍTICO: Atualiza AMBOS os caches para consistência entre telas
    _updateDailyCache();
    _updateWeeklyCache();

    // ✅ Atualização otimista do histórico (sem reload completo)
    _updateHistoryOptimistically(task, newStatus == TaskStatus.done, date);

    _recalculateSummary();
    notifyListeners(); // UI atualiza IMEDIATAMENTE

    // 2. Persistir no backend (em background)
    try {
      await _apiService.toggleRepeatableTask(task.id, date);
    } catch (e) {
      // 🔥 ROLLBACK: Restaura estado original se API falhar
      _dailyTasks.clear();
      _dailyTasks.addAll(originalDailyTasks);
      _weeklyTasks.clear();
      _weeklyTasks.addAll(originalWeeklyTasks);
      
      _updateDailyCache();
      _updateWeeklyCache();
      _recalculateSummary();
      _errorMessage = "Erro ao salvar status: $e";
      notifyListeners();
    } finally {
      // 🔥 CRÍTICO: Libera a flag de operação
      _isOperationInProgress = false;
    }
  }


  // ==================== FOLLOW-UP ====================

  Future<void> loadDelegatedTasks() async {
    const cacheKey = 'delegated_all';
    
    // ✅ Se tem cache, usa IMEDIATAMENTE e NÃO mostra loading
    if (_delegatedTasksCache.containsKey(cacheKey)) {
      _delegatedTasks = _delegatedTasksCache[cacheKey]!;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      
      // ✅ Revalida em background (silent refresh)
      _revalidateDelegatedTasks(cacheKey);
      return;
    }

    // ✅ Sem cache: mostra loading
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newTasks = await _apiService.getDelegatedTasks();
      
      _delegatedTasksCache[cacheKey] = newTasks;
      _delegatedTasks = newTasks;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _delegatedTasks = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ NOVO: Revalida cache de delegadas em background
  Future<void> _revalidateDelegatedTasks(String cacheKey) async {
    try {
      final newTasks = await _apiService.getDelegatedTasks();
      
      // ✅ Atualiza cache silenciosamente
      _delegatedTasksCache[cacheKey] = newTasks;
      
      // ✅ Só atualiza a tela se houve mudanças
      if (_delegatedTasks.length != newTasks.length || 
          !_listsAreEqual(_delegatedTasks, newTasks)) {
        _delegatedTasks = newTasks;
        notifyListeners();
      }
    } catch (e) {
      // ✅ Falha silenciosa: mantém cache antigo
    }
  }

  // ✅ NOVO: Helper para comparar listas de tarefas
  bool _listsAreEqual(List<Task> a, List<Task> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].status != b[i].status) return false;
    }
    return true;
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

  /// ✅ Atualiza o cache da weekly com a lista atual (sem reload)
  void _updateWeeklyCache() {
    if (_weekStart != null && _weekEnd != null) {
      final weekKey = '${_dateKey(_weekStart!)}_${_dateKey(_weekEnd!)}';
      _weeklyTasksCache[weekKey] = List.from(_weeklyTasks);
    }
  }

  /// 🔥 NOVO: Atualiza o cache da daily com a lista atual (sem reload)
  void _updateDailyCache() {
    final dateKey = _dateKey(_selectedDate);
    _dailyTasksCache[dateKey] = List.from(_dailyTasks);
    // Também atualiza o summary no cache se disponível
    if (_summary != null) {
      _dailySummaryCache[dateKey] = _summary!;
    }
  }

  // ==================== WEEKLY TASKS (VERSÃO COM CACHE) ====================

  Future<void> loadWeeklyTasks(DateTime startDate, DateTime endDate) async {
  final weekKey = '${_dateKey(startDate)}_${_dateKey(endDate)}';
  _weekStart = startDate;
  _weekEnd = endDate;
  
  // ✅ Se tem cache, usa IMEDIATAMENTE
  if (_weeklyTasksCache.containsKey(weekKey)) {
    _weeklyTasks = _weeklyTasksCache[weekKey]!;
    _weeklyConfigs = _weeklyConfigsCache[weekKey]!;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    
    // ✅ Revalida em background
    _revalidateWeeklyTasks(startDate, endDate, weekKey);
    return;
  }

  // ✅ Sem cache: mostra loading
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    // ✅ Busca configs da semana (1 request)
    final weeklyResult = await _apiService.getWeeklyTasks(startDate, endDate);
    _weeklyConfigs = (weeklyResult['daily_configs'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, (value as num).toDouble()));

    // ✅ Busca tarefas dia a dia (7 requests, mas usa cache individual)
    final weekStartDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final days = List.generate(7, (i) => weekStartDateOnly.add(Duration(days: i)));

    final dailyResults = await Future.wait(
      days.map((date) async {
        final dateKey = _dateKey(date);
        
        // ✅ Se tem cache do dia, usa
        if (_dailyTasksCache.containsKey(dateKey)) {
          return {'tasks': _dailyTasksCache[dateKey]!};
        }
        
        // ✅ Sem cache: busca da API
        return await _apiService.getDailyTasks(date);
      })
    );

    // ✅ Monta lista única de tarefas
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

    // ✅ Remove duplicatas (tarefas repetíveis aparecem em vários dias)
    final unique = <String, Task>{};
    for (final t in all) {
      final dayKey = '${t.dateScheduled.year}-${t.dateScheduled.month.toString().padLeft(2, '0')}-${t.dateScheduled.day.toString().padLeft(2, '0')}';
      unique['${t.id}_$dayKey'] = t;
    }

    _weeklyTasks = unique.values.toList();

    // ✅ Ordenação
    _weeklyTasks.sort((a, b) {
      final catComp = _energyLevelOrder(a.energyLevel)
          .compareTo(_energyLevelOrder(b.energyLevel));
      if (catComp != 0) return catComp;
      
      final aContext = a.contextTag ?? 'zzz';
      final bContext = b.contextTag ?? 'zzz';
      final contextComp = aContext.compareTo(bContext);
      if (contextComp != 0) return contextComp;
      
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    // ✅ Salva no cache
    _weeklyTasksCache[weekKey] = _weeklyTasks;
    _weeklyConfigsCache[weekKey] = _weeklyConfigs;
    _errorMessage = null;
  } catch (e) {
    _errorMessage = e.toString();
    _weeklyTasks = [];
    _weeklyConfigs = {};
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

// ✅ NOVO: Revalida cache em background (COM PROTEÇÃO CONTRA FLIP-FLOP)
Future<void> _revalidateWeeklyTasks(DateTime startDate, DateTime endDate, String weekKey) async {
  // 🔥 CRÍTICO: Captura o timestamp ANTES de chamar a API
  final revalidationStartTime = DateTime.now();
  
  try {
    // 🔥 NÃO revalida se há operação em andamento
    if (_isOperationInProgress) {
      return;
    }
    
    final weeklyResult = await _apiService.getWeeklyTasks(startDate, endDate);
    
    // 🔥 CRÍTICO: Ignora dados da API se houve modificação LOCAL mais recente
    if (_lastLocalModification.isAfter(revalidationStartTime)) {
      return;
    }
    
    // 🔥 CRÍTICO: Verifica novamente após a chamada async
    if (_isOperationInProgress) {
      return;
    }
    
    final newConfigs = (weeklyResult['daily_configs'] as Map<String, dynamic>)
        .map((key, value) => MapEntry(key, (value as num).toDouble()));

    final weekStartDateOnly = DateTime(startDate.year, startDate.month, startDate.day);
    final days = List.generate(7, (i) => weekStartDateOnly.add(Duration(days: i)));

    final dailyResults = await Future.wait(days.map(_apiService.getDailyTasks));
    
    // 🔥 CRÍTICO: Verifica NOVAMENTE após as chamadas de daily (são muitas!)
    if (_lastLocalModification.isAfter(revalidationStartTime) || _isOperationInProgress) {
      return;
    }

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

    final newTasks = unique.values.toList();

    newTasks.sort((a, b) {
      final catComp = _energyLevelOrder(a.energyLevel)
          .compareTo(_energyLevelOrder(b.energyLevel));
      if (catComp != 0) return catComp;
      
      final aContext = a.contextTag ?? 'zzz';
      final bContext = b.contextTag ?? 'zzz';
      final contextComp = aContext.compareTo(bContext);
      if (contextComp != 0) return contextComp;
      
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    _weeklyTasksCache[weekKey] = newTasks;
    _weeklyConfigsCache[weekKey] = newConfigs;
    
    final currentWeekKey = '${_dateKey(_weekStart!)}_${_dateKey(_weekEnd!)}';
    if (currentWeekKey == weekKey) {
      _weeklyTasks = newTasks;
      _weeklyConfigs = newConfigs;
      notifyListeners();
    }
  } catch (e) {
    // Falha silenciosa
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
        
        // ✅ Adiciona à weekly se estiver no período carregado
        if (_weekStart != null && _weekEnd != null) {
          final taskDate = newTask.dateScheduled;
          if (!taskDate.isBefore(_weekStart!) && !taskDate.isAfter(_weekEnd!)) {
            _weeklyTasks.add(newTask);
            _updateWeeklyCache();
          }
        }
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
      _delegatedTasksCache.clear();
      _dailyTasksCache.clear();
      _weeklyTasksCache.clear();
    }

    // ✅ NOVO: Invalida caches ao converter normal → repetível
    if (updates.containsKey('is_repeatable') && updates['is_repeatable'] == true) {
      _dailyTasksCache.clear();
      _weeklyTasksCache.clear();
    }

    // ✅ CORREÇÃO CRÍTICA: Preserva o status atual se NÃO estamos alterando o status explicitamente
    final finalStatus = updates.containsKey('status')
        ? updatedFromApi.status
        : (existing?.status ?? updatedFromApi.status);

    void updateList(List<Task> list) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].id == taskId) {
          list[i] = Task(
            id: list[i].id,
            title: updatedFromApi.title,
            description: updatedFromApi.description,
            energyLevel: updatedFromApi.energyLevel,
            durationMinutes: updatedFromApi.durationMinutes,
            status: finalStatus,  // ✅ Usa o status preservado
            dateScheduled: isRepeatable ? list[i].dateScheduled : updatedFromApi.dateScheduled,
            scheduledTime: updatedFromApi.scheduledTime,
            roleTag: updatedFromApi.roleTag,
            contextTag: updatedFromApi.contextTag,
            delegatedTo: updatedFromApi.delegatedTo,
            followUpDate: updatedFromApi.followUpDate,
            isRepeatable: updatedFromApi.isRepeatable,
            repeatCount: isRepeatable ? list[i].repeatCount : updatedFromApi.repeatCount,
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
  // 🔥 CRÍTICO: Marca que uma operação está em andamento
  _isOperationInProgress = true;
  _lastLocalModification = DateTime.now();
  
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

  if (task == null) {
    _isOperationInProgress = false;
    return false;
  }

  // 🔥 Guarda estado original para rollback em caso de erro
  final originalDailyTasks = List<Task>.from(_dailyTasks);
  final originalWeeklyTasks = List<Task>.from(_weeklyTasks);

  final newStatusEnum = task.status == TaskStatus.done ? TaskStatus.active : TaskStatus.done;
  final updatedTask = task.copyWith(status: newStatusEnum);
  final isDelegated = updatedTask.delegatedTo != null && updatedTask.delegatedTo!.isNotEmpty;

  // 🔥 OPTIMISTIC UPDATE: Atualiza AMBAS as listas (Daily e Weekly) para consistência
  if (isDaily) {
    _dailyTasks[index] = updatedTask;
    // 🔥 TAMBÉM atualiza a Weekly se a tarefa existir lá
    final weeklyIndex = _weeklyTasks.indexWhere((t) => t.id == taskId);
    if (weeklyIndex != -1) {
      _weeklyTasks[weeklyIndex] = updatedTask;
    }
  } else {
    if (isDelegated && newStatusEnum == TaskStatus.active) {
      _weeklyTasks.removeAt(index);
    } else {
      _weeklyTasks[index] = updatedTask;
    }
    // 🔥 TAMBÉM atualiza a Daily se a tarefa existir lá
    final dailyIndex = _dailyTasks.indexWhere((t) => t.id == taskId);
    if (dailyIndex != -1) {
      _dailyTasks[dailyIndex] = updatedTask;
    }
  }

  // 🔥 CRÍTICO: Atualiza os CACHES também (não só as listas em memória)
  _updateDailyCache();
  _updateWeeklyCache();

  _recalculateSummary();
  notifyListeners();

  try {
    if (task.isRepeatable) {
      await _apiService.toggleRepeatableTask(taskId, task.dateScheduled);
    } else {
      final newStatusString = newStatusEnum == TaskStatus.done ? 'DONE' : 'ACTIVE';
      await _apiService.updateTask(taskId, {'status': newStatusString});
    }
    
    // ✅ Atualização otimista do histórico (sem reload completo)
    _updateHistoryOptimistically(task, newStatusEnum == TaskStatus.done, task.dateScheduled);
    
    return true;
  } catch (e) {
    // 🔥 ROLLBACK: Restaura estado original se API falhar
    _dailyTasks.clear();
    _dailyTasks.addAll(originalDailyTasks);
    _weeklyTasks.clear();
    _weeklyTasks.addAll(originalWeeklyTasks);
    _updateDailyCache();
    _updateWeeklyCache();
    _recalculateSummary();
    
    _errorMessage = "Erro ao sincronizar: $e";
    notifyListeners();
    return false;
  } finally {
    // 🔥 CRÍTICO: Libera a flag de operação
    _isOperationInProgress = false;
  }
}



  // ✅ Excluir tarefa
  Future<bool> deleteTask(int taskId) async {
    try {
      await _apiService.deleteTask(taskId);

      _dailyTasks.removeWhere((t) => t.id == taskId);
      _delegatedTasks.removeWhere((t) => t.id == taskId);
      _weeklyTasks.removeWhere((t) => t.id == taskId);
      
      // ✅ Atualiza caches com as listas já modificadas
      _updateWeeklyCache();
      
      // ✅ Remove do histórico também
      _historyTasks.removeWhere((h) => h.id == taskId);
      final cacheKey = _historySearchTerm ?? '__all__';
      _historyCache[cacheKey] = List.from(_historyTasks);

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
final Map<String, DashboardStats> _dashboardStatsCache = {};
final Map<String, List<HistoryTask>> _historyCache = {};

DashboardStats? get dashboardStats => _dashboardStats;
String get currentPeriod => _currentPeriod;

Future<void> loadDashboardStats(String period) async {
  _currentPeriod = period;
  
  // ✅ Se tem cache, usa IMEDIATAMENTE
  if (_dashboardStatsCache.containsKey(period)) {
    _dashboardStats = _dashboardStatsCache[period]!;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
    
    // ✅ Revalida em background
    _revalidateDashboardStats(period);
    return;
  }

  // ✅ Sem cache: mostra loading
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final data = await _apiService.getDashboardStats(period);
    final stats = DashboardStats.fromJson(data);
    
    _dashboardStatsCache[period] = stats;
    _dashboardStats = stats;
    _errorMessage = null;
  } catch (e) {
    _errorMessage = e.toString();
    _dashboardStats = null;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

// ✅ NOVO: Revalida stats em background
Future<void> _revalidateDashboardStats(String period) async {
  try {
    final data = await _apiService.getDashboardStats(period);
    final stats = DashboardStats.fromJson(data);
    
    _dashboardStatsCache[period] = stats;
    
    // Só atualiza se ainda estiver no mesmo período
    if (_currentPeriod == period) {
      _dashboardStats = stats;
      notifyListeners();
    }
  } catch (e) {
    // Falha silenciosa
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

/// ✅ Atualização otimista do histórico (sem reload completo)
/// Quando tarefa é marcada done: adiciona ao topo do histórico
/// Quando tarefa é desmarcada: remove do histórico
void _updateHistoryOptimistically(Task task, bool isDone, DateTime dateScheduled) {
  if (isDone) {
    // Adiciona ao topo do histórico
    final historyTask = HistoryTask(
      id: task.id,
      title: task.title,
      energyLevel: task.energyLevel,
      durationMinutes: task.durationMinutes,
      completedAt: DateTime.now(),
      dateScheduled: dateScheduled,
      contextTag: task.contextTag,
      roleTag: task.roleTag,
      description: task.description,
    );
    _historyTasks.insert(0, historyTask);
  } else {
    // Remove do histórico (pode ter múltiplas entradas para repetíveis)
    _historyTasks.removeWhere((h) => 
      h.id == task.id && 
      h.dateScheduled.year == dateScheduled.year &&
      h.dateScheduled.month == dateScheduled.month &&
      h.dateScheduled.day == dateScheduled.day
    );
  }
  
  // ✅ Atualiza o cache com a lista modificada (não limpa!)
  final cacheKey = _historySearchTerm ?? '__all__';
  _historyCache[cacheKey] = List.from(_historyTasks);
}


Future<void> loadHistory({bool loadMore = false, String? searchTerm}) async {
  final isNewSearch = searchTerm != _historySearchTerm;
  final cacheKey = searchTerm ?? '__all__';
  
  // ✅ Se é nova busca ou reset, limpa estado
  if (isNewSearch || !loadMore) {
    _currentHistoryPage = 1;
    _hasMoreHistory = true;
    _historySearchTerm = searchTerm;
    
    // ✅ Verifica cache para nova busca
    if (!loadMore && _historyCache.containsKey(cacheKey)) {
      _historyTasks = _historyCache[cacheKey]!;
      _isLoading = false;
      _errorMessage = null;
      notifyListeners();
      
      // Revalida em background
      _revalidateHistory(cacheKey, searchTerm);
      return;
    }
    
    _historyTasks = [];
  }

  if (_isLoading) return;
  if (loadMore && !_hasMoreHistory) return;

  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final data = await _apiService.getTasksHistory(
      page: _currentHistoryPage,
      perPage: 20,
      searchTerm: _historySearchTerm,
    );

    final tasks = (data['tasks'] as List)
        .map((json) => HistoryTask.fromJson(json))
        .toList();

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
    
    if (newTasks.isNotEmpty) {
      _currentHistoryPage++;
    }

    if (_currentHistoryPage == 2) {
      _historyCache[cacheKey] = List.from(_historyTasks);
    }

    _errorMessage = null;
  } catch (e) {
    _errorMessage = e.toString();
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

// ✅ NOVO: Revalida histórico em background
Future<void> _revalidateHistory(String cacheKey, String? searchTerm) async {
  try {
    final data = await _apiService.getTasksHistory(
      page: 1,
      perPage: 20,
      searchTerm: searchTerm,
    );

    final tasks = (data['tasks'] as List)
        .map((json) => HistoryTask.fromJson(json))
        .toList();

    // Atualiza cache
    _historyCache[cacheKey] = tasks;
    
    // Se ainda estiver na mesma busca e é página inicial
    if (_historySearchTerm == searchTerm && _currentHistoryPage <= 2) {
      _historyTasks = tasks;
      _currentHistoryPage = 2;
      final pagination = data['pagination'];
      _hasMoreHistory = pagination['has_next'];
      notifyListeners();
    }
  } catch (e) {
    // Falha silenciosa
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


