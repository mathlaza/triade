import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/screens/add_task_screen.dart';

class PendingReviewModal extends StatefulWidget {
  final List<Task> tasks;

  const PendingReviewModal({super.key, required this.tasks});

  @override
  State<PendingReviewModal> createState() => _PendingReviewModalState();
}

class _PendingReviewModalState extends State<PendingReviewModal> {
  late List<Task> _pendingTasks;
  final Set<int> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _pendingTasks = List.from(widget.tasks);
  }

  void _markProcessing(int taskId, bool processing) {
    setState(() {
      if (processing) {
        _processingIds.add(taskId);
      } else {
        _processingIds.remove(taskId);
      }
    });
  }

  void _removeTask(int taskId) {
    setState(() {
      _pendingTasks.removeWhere((t) => t.id == taskId);
      _processingIds.remove(taskId);
    });

    if (_pendingTasks.isEmpty && mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _rescheduleTask(Task task) async {
    _markProcessing(task.id, true);
    HapticFeedback.lightImpact();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTaskScreen(
          selectedDate: DateTime.now(),
          taskToEdit: task,
        ),
      ),
    );

    if (result == true && mounted) {
      _removeTask(task.id);
    } else {
      _markProcessing(task.id, false);
    }
  }

  Future<void> _deleteTask(Task task) async {
    _markProcessing(task.id, true);
    HapticFeedback.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Excluir Tarefa',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Excluir "${task.title}"?',
          style: const TextStyle(color: Color(0xFF98989D)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Color(0xFF98989D)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Excluir',
              style: TextStyle(color: Color(0xFFFF453A)),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<TaskProvider>();
      await provider.deleteTask(task.id);
      if (mounted) {
        _removeTask(task.id);
      }
    } else {
      _markProcessing(task.id, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF38383A),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: _pendingTasks.isEmpty
                    ? _buildEmptyState()
                    : _buildTaskList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF38383A),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF9500).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.pending_actions_rounded,
              color: Color(0xFFFF9500),
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ritual do Boot',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _pendingTasks.length == 1
                ? '1 tarefa pendente'
                : '${_pendingTasks.length} tarefas pendentes',
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF98989D),
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xFF30D158),
            size: 48,
          ),
          SizedBox(height: 12),
          Text(
            'Tudo resolvido!',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _pendingTasks.length,
      itemBuilder: (context, index) {
        final task = _pendingTasks[index];
        final isProcessing = _processingIds.contains(task.id);
        return _buildTaskCard(task, isProcessing);
      },
    );
  }

  Widget _buildTaskCard(Task task, bool isProcessing) {
    final energyColor = task.energyLevel.color;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isProcessing ? 0.5 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: energyColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 32,
                    decoration: BoxDecoration(
                      color: energyColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${task.durationMinutes}min • ${task.energyLevel.label}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF98989D),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.calendar_today_rounded,
                      label: 'Reagendar',
                      color: const Color(0xFF0A84FF),
                      isLoading: isProcessing,
                      onTap: isProcessing ? null : () => _rescheduleTask(task),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.delete_outline_rounded,
                      label: 'Excluir',
                      color: const Color(0xFFFF453A),
                      isLoading: isProcessing,
                      onTap: isProcessing ? null : () => _deleteTask(task),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isLoading,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
              )
            else
              Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
