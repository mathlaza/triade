import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/widgets/follow_up/follow_up_widgets.dart';

// ✅ Data class para Selector - minimiza rebuilds
class _FollowUpViewData {
  final bool isLoading;
  final List<Task> delegatedTasks;
  final String? errorMessage;

  _FollowUpViewData({
    required this.isLoading,
    required this.delegatedTasks,
    required this.errorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FollowUpViewData &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          delegatedTasks.length == other.delegatedTasks.length &&
          errorMessage == other.errorMessage &&
          _tasksEqual(delegatedTasks, other.delegatedTasks);

  bool _tasksEqual(List<Task> a, List<Task> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].status != b[i].status) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(isLoading, delegatedTasks.length, errorMessage);
}

class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({super.key});

  @override
  State<FollowUpScreen> createState() => FollowUpScreenState();
}

class FollowUpScreenState extends State<FollowUpScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Constantes de design - Dark Premium Theme (mantidas para uso local)
  static const Color _backgroundColor = Color(0xFF000000);
  static const Color _surfaceColor = Color(0xFF1C1C1E);
  static const Color _accentGold = Color(0xFFFFD60A);
  static const Color _errorRed = Color(0xFFFF453A);
  static const Color _successGreen = Color(0xFF32D74B);
  static const Color _warningOrange = Color(0xFFFF9F0A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDelegatedTasks();
    });
  }

  void onBecameVisible() {
    _loadDelegatedTasks();
  }

  Future<void> _loadDelegatedTasks() async {
    if (!mounted) return;
    await context.read<TaskProvider>().loadDelegatedTasks();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Column(
        children: [
          const FollowUpHeader(),
          Expanded(
            child: Selector<TaskProvider, _FollowUpViewData>(
              selector: (_, provider) => _FollowUpViewData(
                isLoading: provider.isLoading,
                delegatedTasks: provider.delegatedTasks,
                errorMessage: provider.errorMessage,
              ),
              shouldRebuild: (prev, next) => prev != next,
              builder: (context, data, child) {
                if (data.isLoading && data.delegatedTasks.isEmpty) {
                  return const FollowUpLoadingState();
                }

                if (data.errorMessage != null && data.delegatedTasks.isEmpty) {
                  return FollowUpErrorState(
                    errorMessage: data.errorMessage!,
                    onRetry: _loadDelegatedTasks,
                  );
                }

                if (data.delegatedTasks.isEmpty) {
                  return const FollowUpEmptyState();
                }

                return _buildContent(data.delegatedTasks);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<Task> delegatedTasks) {
    final overdue = <Task>[];
    final today = <Task>[];
    final upcoming = <Task>[];
    final completed = <Task>[];

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    for (var task in delegatedTasks) {
      if (task.status == TaskStatus.done) {
        completed.add(task);
        continue;
      }
      
      if (task.followUpDate == null) {
        upcoming.add(task);
      } else {
        final followUpDate = DateTime(
          task.followUpDate!.year,
          task.followUpDate!.month,
          task.followUpDate!.day,
        );

        if (followUpDate.isBefore(todayDate)) {
          overdue.add(task);
        } else if (followUpDate.isAtSameMomentAs(todayDate)) {
          today.add(task);
        } else {
          upcoming.add(task);
        }
      }
    }

    final pending = overdue.length + today.length + upcoming.length;

    return RefreshIndicator(
      onRefresh: _loadDelegatedTasks,
      color: _accentGold,
      backgroundColor: _surfaceColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          FollowUpStatsCard(
            pendingCount: pending,
            overdueCount: overdue.length,
            completedCount: completed.length,
          ),
          if (overdue.isNotEmpty)
            _buildSection('Atrasadas', overdue, _errorRed, Icons.warning_rounded),
          if (today.isNotEmpty)
            _buildSection('Follow-up Hoje', today, _warningOrange, Icons.today_rounded),
          if (upcoming.isNotEmpty)
            _buildSection('Próximas', upcoming, _successGreen, Icons.event_rounded),
          if (completed.isNotEmpty)
            _buildSection('Concluídas', completed, _successGreen, Icons.check_circle_rounded),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Task> tasks, Color color, IconData icon) {
    final sortedTasks = List<Task>.from(tasks);
    sortedTasks.sort((a, b) {
      if (a.followUpDate == null && b.followUpDate == null) return 0;
      if (a.followUpDate == null) return 1;
      if (b.followUpDate == null) return -1;
      return a.followUpDate!.compareTo(b.followUpDate!);
    });

    return FollowUpSection(
      title: title,
      icon: icon,
      color: color,
      count: tasks.length,
      children: sortedTasks.map((task) => DelegatedTaskCard(
        task: task,
        isCompleted: task.status == TaskStatus.done,
        statusColor: color,
        onToggleCompletion: () => _toggleTaskCompletion(task),
        onConfirmReassign: () => ReassignConfirmDialog.show(context, task),
        onReassign: () => _reassignTask(task),
      )).toList(),
    );
  }

  Future<void> _reassignTask(Task task) async {
    final provider = context.read<TaskProvider>();

    // Remove imediatamente da lista local (optimistic update)
    setState(() {
      provider.delegatedTasks.removeWhere((t) => t.id == task.id);
    });

    // Depois faz as chamadas à API em background
    if (task.status == TaskStatus.done) {
      await provider.updateTask(task.id, {'status': 'ACTIVE'});
      await provider.updateTask(task.id, {'delegated_to': null});
    } else {
      await provider.updateTask(task.id, {'delegated_to': null});
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.black, size: 20),
              SizedBox(width: 10),
              Text('Tarefa reassumida', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: _accentGold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    HapticFeedback.lightImpact();
    final provider = context.read<TaskProvider>();
    
    final newStatus = task.status == TaskStatus.done ? TaskStatus.active : TaskStatus.done;
    final newStatusString = newStatus == TaskStatus.done ? 'DONE' : 'ACTIVE';
    
    // Optimistic update - atualiza localmente primeiro
    final index = provider.delegatedTasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      final updatedTask = task.copyWith(status: newStatus);
      setState(() {
        provider.delegatedTasks[index] = updatedTask;
      });
    }
    
    // Depois faz a chamada à API em background
    provider.updateTask(task.id, {'status': newStatusString});

    if (mounted) {
      final message = newStatus == TaskStatus.done ? 'Tarefa concluída' : 'Tarefa reativada';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newStatus == TaskStatus.done ? Icons.check_circle : Icons.refresh,
                color: Colors.black,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(message, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
            ],
          ),
          backgroundColor: newStatus == TaskStatus.done ? _successGreen : _accentGold,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}