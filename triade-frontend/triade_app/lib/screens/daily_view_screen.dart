import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/providers/config_provider.dart';
import 'package:triade_app/widgets/task_card.dart';
import 'package:triade_app/widgets/progress_bar.dart';
import 'package:triade_app/screens/add_task_screen.dart';
import 'package:triade_app/screens/pending_review_modal.dart';
import 'package:triade_app/config/constants.dart';

class DailyViewScreen extends StatefulWidget {
  const DailyViewScreen({super.key});

  @override
  State<DailyViewScreen> createState() => DailyViewScreenState();
}

class DailyViewScreenState extends State<DailyViewScreen> {
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingReview();
      _loadData();
    });
  }

  void onBecameVisible() {
  _loadData();
}

  Future<void> _checkPendingReview() async {
    final provider = context.read<TaskProvider>();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final pendingTasks = await provider.getPendingReview(yesterday);

    if (pendingTasks.isNotEmpty && mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PendingReviewModal(tasks: pendingTasks),
      );
    }
  }

  Future<void> _loadData() async {
    await context.read<ConfigProvider>().loadDailyConfig(selectedDate);
    await context.read<TaskProvider>().loadDailyTasks(selectedDate);
  }

  bool _isFutureDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return selected.isAfter(today);
  }

  bool _isToday() {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Column(
      children: [
        // AppBar manual (sem usar AppBar widget)
        Container(
          color: AppConstants.primaryColor,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 8,
            left: 16,
            right: 16,
          ),
          child: Row(
            children: [
              const Text(
                'Tríade do Tempo',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  // TODO: Tela de configuração
                },
              ),
            ],
          ),
        ),
        _buildDateSelector(),
        Expanded(
          child: Consumer<TaskProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                );
              }

              if (provider.tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhuma tarefa para este dia',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  children: [
                    if (provider.summary != null)
                      DailyProgressBar(
                        usedHours: provider.summary!.usedHours,
                        availableHours: provider.summary!.availableHours,
                      ),
                    _buildTaskSection('🔴 Urgente', provider.urgentTasks),
                    _buildTaskSection('🟢 Importante', provider.importantTasks),
                    _buildTaskSection('⚪ Circunstancial', provider.circumstantialTasks),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTaskScreen(selectedDate: selectedDate),
          ),
        );
        if (result == true) {
          _loadData();
        }
      },
      icon: const Icon(Icons.add),
      label: const Text('Nova Tarefa'),
      backgroundColor: AppConstants.primaryColor,
    ),
  );
}


  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão Anterior
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.subtract(const Duration(days: 1));
              });
              _loadData();
            },
          ),

          // Data (clicável para DatePicker)
          Expanded(
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (date != null) {
                  setState(() {
                    selectedDate = date;
                  });
                  _loadData();
                }
              },
              child: Column(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_isToday())
                    Text(
                      _isFutureDate() ? 'Futuro' : 'Passado',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isFutureDate() ? Colors.orange : Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Botão "Hoje" (só aparece se não estiver no dia atual)
          if (!_isToday())
            TextButton.icon(
              onPressed: () {
                setState(() {
                  selectedDate = DateTime.now();
                });
                _loadData();
              },
              icon: const Icon(Icons.today, size: 20),
              label: const Text('Hoje'),
              style: TextButton.styleFrom(
                foregroundColor: AppConstants.primaryColor,
              ),
            )
          else
            const SizedBox(width: 80), // Espaço para manter simetria

          // Botão Próximo
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.add(const Duration(days: 1));
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTaskSection(String title, List tasks) {
  if (tasks.isEmpty) return const SizedBox.shrink();

  final isFuture = _isFutureDate();

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      ...tasks.map((task) {
  final provider = context.read<TaskProvider>();

  Future<void> deleteCb() async {
    await provider.deleteTask(task.id);
  }

  final card = TaskCard(
    task: task,
    isFutureRepeatable: false,
    onTap: () async {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddTaskScreen(
            selectedDate: task.dateScheduled,
            taskToEdit: task,
          ),
        ),
      );
      if (result == true) {
        _loadData();
      }
    },
    onDelete: deleteCb,
                          onToggleDone: () async {
                        await provider.toggleTaskDone(task.id);
                      },

  );

  // ✅ força swipe-to-delete nas repetíveis (mesmo que o TaskCard bloqueie)
  if (!task.isRepeatable) return card;

  return Dismissible(
    key: ValueKey('task_${task.id}_${task.dateScheduled.toIso8601String()}'),
    direction: DismissDirection.endToStart,
    confirmDismiss: (_) async {
      await deleteCb();
      return true;
    },
    background: Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.red,
      child: const Icon(Icons.delete, color: Colors.white),
    ),
    child: card,
  );
}),

    ],
  );
}

}
