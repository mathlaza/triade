import 'package:flutter/foundation.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/models/daily_summary.dart';
import 'package:triade_app/services/api_service.dart';
import 'package:triade_app/config/constants.dart';

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

  // Carregar tarefas do dia (Daily View)
  Future<void> loadDailyTasks(DateTime date) async {
    _isLoading = true;
    _errorMessage = null;
    _selectedDate = date;
    notifyListeners();

    try {
      final result = await _apiService.getDailyTasks(date);
      _dailyTasks = result['tasks'];
      _summary = result['summary'];
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

  // Criar tarefa
  Future<bool> createTask(Task task) async {
    try {
      final newTask = await _apiService.createTask(task);

      // Adicionar na lista correta
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

  // Atualizar tarefa
  Future<bool> updateTask(int taskId, Map<String, dynamic> updates) async {
    try {
      final updatedTask = await _apiService.updateTask(taskId, updates);

      // Atualizar na lista correta
      final dailyIndex = _dailyTasks.indexWhere((t) => t.id == taskId);
      if (dailyIndex != -1) {
        _dailyTasks[dailyIndex] = updatedTask;
      }

      final delegatedIndex = _delegatedTasks.indexWhere((t) => t.id == taskId);
      if (delegatedIndex != -1) {
        if (updatedTask.status != TaskStatus.delegated) {
          _delegatedTasks.removeAt(delegatedIndex);
        } else {
          _delegatedTasks[delegatedIndex] = updatedTask;
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

  // Marcar como concluída
  Future<bool> markAsDone(int taskId) async {
    return await updateTask(taskId, {'status': 'DONE'});
  }

  // Excluir tarefa
  Future<bool> deleteTask(int taskId) async {
    try {
      await _apiService.deleteTask(taskId);

      // Remover da lista correta
      _dailyTasks.removeWhere((t) => t.id == taskId);
      _delegatedTasks.removeWhere((t) => t.id == taskId);

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
