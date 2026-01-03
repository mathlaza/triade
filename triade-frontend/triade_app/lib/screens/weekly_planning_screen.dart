import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/screens/add_task_screen.dart';

class WeeklyPlanningScreen extends StatefulWidget {
  const WeeklyPlanningScreen({super.key});

  @override
  State<WeeklyPlanningScreen> createState() => WeeklyPlanningScreenState();
}

class WeeklyPlanningScreenState extends State<WeeklyPlanningScreen> {
  DateTime _currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  String? _selectedContext;

  @override
  void initState() {
    super.initState();
  }

  void onBecameVisible() {
    _loadWeeklyTasks();
  }

  Future<void> _loadWeeklyTasks() async {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    await context.read<TaskProvider>().loadWeeklyTasks(_currentWeekStart, weekEnd);
  }

  bool _isCurrentWeek() {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final currentWeekStartDate = DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
    final selectedWeekStartDate = DateTime(_currentWeekStart.year, _currentWeekStart.month, _currentWeekStart.day);
    return currentWeekStartDate.isAtSameMomentAs(selectedWeekStartDate);
  }

  String _getWeekStatus() {
    if (_isCurrentWeek()) return 'Atual';
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    return _currentWeekStart.isBefore(currentWeekStart) ? 'Passado' : 'Futuro';
  }

  String _getWeekNumber() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final thursday = _currentWeekStart.add(const Duration(days: 3));
    final year = thursday.year;
    final jan4 = DateTime(year, 1, 4);
    final firstThursday = jan4.subtract(Duration(days: (jan4.weekday - 4) % 7));
    final daysDiff = _currentWeekStart.difference(firstThursday).inDays;
    final weekNumber = (daysDiff / 7).floor() + 1;
    return 'Semana $weekNumber de $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: AppConstants.primaryColor,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 8,
              left: 16,
              right: 16,
            ),
            child: const Text(
              'Planejamento Semanal',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildWeekSelector(),
          _buildContextFilters(),
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
                          onPressed: _loadWeeklyTasks,
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final date = _currentWeekStart.add(Duration(days: index));
                    return _buildDayCard(date, provider);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekSelector() {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    final weekNumber = _getWeekNumber();
    final weekStatus = _getWeekStatus();
    Color statusColor = Colors.grey;
    if (weekStatus == 'Atual') {
      statusColor = Colors.blue;
    } else if (weekStatus == 'Passado') {
      statusColor = Colors.grey;
    } else {
      statusColor = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
              });
              _loadWeeklyTasks();
            },
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$weekNumber ($weekStatus)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    if (!_isCurrentWeek())
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _currentWeekStart = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
                            });
                            _loadWeeklyTasks();
                          },
                          child: const Icon(Icons.calendar_today, size: 18, color: Colors.blue),
                        ),
                      ),
                  ],
                ),
                Text(
                  '${DateFormat('dd/MM').format(_currentWeekStart)} - ${DateFormat('dd/MM').format(weekEnd)}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
              });
              _loadWeeklyTasks();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContextFilters() {
    final allContexts = ContextColors.colors.keys.toList();
    return Container(
      height: 50,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allContexts.length + 1, // +1 para o botão "Todos"
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ChoiceChip(
                label: const Text('Todos'),
                selected: _selectedContext == null,
                onSelected: (selected) {
                  setState(() {
                    _selectedContext = null;
                  });
                  _loadWeeklyTasks();
                },
                selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(color: _selectedContext == null ? AppConstants.primaryColor : Colors.grey.shade700),
                side: BorderSide(color: _selectedContext == null ? AppConstants.primaryColor : Colors.grey.shade400),
              ),
            );
          }
          final contextTag = allContexts[index - 1];
          final isSelected = _selectedContext == contextTag;
          final color = ContextColors.getColor(contextTag);
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(contextTag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedContext = selected ? contextTag : null;
                });
                _loadWeeklyTasks();
              },
              selectedColor: color.withOpacity(0.2),
              labelStyle: TextStyle(color: isSelected ? color : Colors.grey.shade700),
              side: BorderSide(color: isSelected ? color : Colors.grey.shade400),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayCard(DateTime date, TaskProvider provider) {
    final dayTasks = provider.weeklyTasks.where((t) {
      final taskDate = DateTime(t.dateScheduled.year, t.dateScheduled.month, t.dateScheduled.day);
      final checkDate = DateTime(date.year, date.month, date.day);
      if (_selectedContext != null && t.contextTag != _selectedContext) {
        return false;
      }
      return taskDate.isAtSameMomentAs(checkDate);
    }).toList();

    dayTasks.sort((a, b) {
      final categoryOrder = {
        TriadCategory.urgent: 0,
        TriadCategory.important: 1,
        TriadCategory.circumstantial: 2,
      };
      return categoryOrder[a.triadCategory]!.compareTo(categoryOrder[b.triadCategory]!);
    });

    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final availableHours = provider.weeklyConfigs[dateKey] ?? 8.0;
    final usedHours = provider.getUsedHours(date);
    final percentage = (usedHours / availableHours).clamp(0.0, 1.0);

    return DragTarget<Task>(
      onWillAccept: (task) {
  if (task == null) return false;
  final bool isRepeatable = task.isRepeatable == true; // ajuste aqui
  return !isRepeatable;
},
      onAccept: (task) async {
        if (!provider.canFitTask(date, task.durationMinutes)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_getDayName(date)} está lotado!'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        final success = await provider.moveTaskToDate(task.id, date);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Tarefa movida para ${_getDayName(date)}'),
              backgroundColor: Colors.green,
            ),
          );
          _loadWeeklyTasks();
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: candidateData.isNotEmpty ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: candidateData.isNotEmpty ? Colors.blue : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_getDayName(date)}, ${DateFormat('dd/MM').format(date)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${usedHours.toStringAsFixed(1)}h / ${availableHours.toStringAsFixed(1)}h',
                      style: TextStyle(
                        fontSize: 14,
                        color: percentage > 1.0 ? Colors.red : Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage > 1.0 ? Colors.red : AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              if (dayTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Text(
                    'Nenhuma tarefa para ${_getDayName(date)}.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ...dayTasks.map((task) {
                return _buildWeeklyTaskCard(task);
              }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // Cor específica para tarefas DONE na Week View
  static const Color _doneTaskBackgroundColor = Color(0xFF8BC34A); // Light Green 500


  int _repeatDayNumber(Task task) {
  final created = DateTime(task.createdAt.year, task.createdAt.month, task.createdAt.day);
  final scheduled = DateTime(task.dateScheduled.year, task.dateScheduled.month, task.dateScheduled.day);
  final diff = scheduled.difference(created).inDays;
  final n = diff + 1; // dia de criação = 1, amanhã = 2...
  return n < 1 ? 1 : n;
}

Widget _buildRepeatSeriesBadge(Task task, bool isDone) {
  if (!task.isRepeatable) return const SizedBox.shrink();

  final n = _repeatDayNumber(task);

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: isDone ? Colors.black.withOpacity(0.08) : Colors.white.withOpacity(0.65),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: isDone ? Colors.black.withOpacity(0.12) : Colors.black.withOpacity(0.15),
        width: 1,
      ),
    ),
    child: Text(
      '#$n', // <-- AQUI está o "#"
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isDone ? Colors.grey.shade700 : Colors.black87,
      ),
    ),
  );
}



  Widget _buildWeeklyTaskCard(Task task) {
  final contextColor = ContextColors.getColor(task.contextTag);
  final isDone = task.status == TaskStatus.done;

  // ✅ Cor de fundo para tarefas ATIVAS (com opacidade)
  final activeBackgroundColor = task.triadCategory.color.withOpacity(0.1);
  // ✅ Cor da borda para tarefas ATIVAS (cor da categoria)
  final activeBorderColor = task.triadCategory.color;

  // TODO: troque isso pelo campo real do seu model:
  // exemplos comuns: task.isRecurring, task.isRepeatable, task.isRepeating, task.repeatEnabled
  final bool isRepeatable = task.isRepeatable == true;

  // Card "normal" (sem drag) — reutilizado nos dois casos
  final Widget card = GestureDetector(
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
        _loadWeeklyTasks();
      }
    },
    child: _buildWeeklyTaskCardContent(
      task,
      contextColor,
      isDone,
      activeBackgroundColor,
      activeBorderColor,
    ),
  );

  // ✅ Se for repetível: NÃO pode arrastar na week view
  if (isRepeatable) {
    return card;
  }

  // ✅ Caso normal: pode arrastar
  return Draggable<Task>(
    data: task,
    feedback: Material(
      elevation: 4.0,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDone
              ? _doneTaskBackgroundColor.withOpacity(0.7)
              : activeBackgroundColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDone ? _doneTaskBackgroundColor : activeBorderColor,
            width: 2,
          ),
        ),
        child: Text(
          task.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            decoration: isDone ? TextDecoration.lineThrough : null,
            color: isDone ? Colors.grey.shade600 : Colors.black87,
          ),
        ),
      ),
    ),
    childWhenDragging: Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Opacity(
        opacity: 0.5,
        child: _buildWeeklyTaskCardContent(
          task,
          contextColor,
          isDone,
          activeBackgroundColor,
          activeBorderColor,
        ),
      ),
    ),
    child: card,
  );
}


  // ✅ Novo método para construir o conteúdo do card, reutilizável
 Widget _buildWeeklyTaskCardContent(
  Task task,
  Color contextColor,
  bool isDone,
  Color activeBackgroundColor,
  Color activeBorderColor,
) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isDone ? _doneTaskBackgroundColor : activeBackgroundColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isDone ? _doneTaskBackgroundColor : activeBorderColor,
        width: 2,
      ),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  decoration: isDone ? TextDecoration.lineThrough : null,
                  color: isDone ? Colors.grey.shade600 : Colors.black87,
                ),
              ),
              if (task.contextTag != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(Icons.label, size: 14, color: contextColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          task.contextTag!,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: contextColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(width: 10),

        // LADO DIREITO: badge + duração (não disputa com o título)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (task.isRepeatable) _buildRepeatSeriesBadge(task, isDone),
            if (task.isRepeatable) const SizedBox(height: 6),
            Text(
              '${(task.durationMinutes / 60).toStringAsFixed(1)}h',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}


  String _getDayName(DateTime date) {
    const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return days[date.weekday - 1];
  }
}
