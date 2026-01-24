import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  DateTime _currentWeekStart =
      DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
  String? _selectedContext;

  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  Timer? _weekChangeTimer;
  Timer? _positionCheckTimer;
  
  double _lastDragX = 0;
  int _activeDirection = 0;
  DateTime? _lastUpdateTime;

  bool _isDraggingTask = false;

  void onBecameVisible() {
    _stopAutoScroll();
    _stopWeekChange();
    _stopPositionCheckTimer();
    _loadWeeklyTasks();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _weekChangeTimer?.cancel();
    _positionCheckTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadWeeklyTasks() async {
    final weekEnd = _currentWeekStart.add(const Duration(days: 6));
    await context
        .read<TaskProvider>()
        .loadWeeklyTasks(_currentWeekStart, weekEnd);
  }

  bool _isCurrentWeek() {
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    final currentWeekStartDate = DateTime(
        currentWeekStart.year, currentWeekStart.month, currentWeekStart.day);
    final selectedWeekStartDate = DateTime(
        _currentWeekStart.year, _currentWeekStart.month, _currentWeekStart.day);
    return currentWeekStartDate.isAtSameMomentAs(selectedWeekStartDate);
  }

  String _getWeekStatus() {
    if (_isCurrentWeek()) return 'Atual';
    final now = DateTime.now();
    final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
    return _currentWeekStart.isBefore(currentWeekStart) ? 'Passado' : 'Futuro';
  }

  String _getWeekNumber() {
    final thursday = _currentWeekStart.add(const Duration(days: 3));
    final year = thursday.year;
    final jan4 = DateTime(year, 1, 4);
    final firstThursday = jan4.subtract(Duration(days: (jan4.weekday - 4) % 7));
    final daysDiff = _currentWeekStart.difference(firstThursday).inDays;
    final weekNumber = (daysDiff / 7).floor() + 1;
    return 'S$weekNumber de $year';
  }

  // Atualiza a posição E registra timestamp
 void _handleDragUpdate(DragUpdateDetails details) {
  final screenHeight = MediaQuery.of(context).size.height;
  final dy = details.globalPosition.dy;
  final dx = details.globalPosition.dx;

  _lastDragX = dx;
  _lastUpdateTime = DateTime.now();

  // ✅ CORREÇÃO: Calcula o offset do topo (AppBar + WeekSelector + ContextFilters)
  final topOffset = MediaQuery.of(context).padding.top + 8 + 8 + 52 + 50; // AppBar + margins + selector + filters
  
  const edgeThreshold = 100.0;
  const scrollSpeed = 10.0;

  // Ajusta dy para considerar apenas a área do ListView
  final adjustedDy = dy - topOffset;
  final listViewHeight = screenHeight - topOffset;
  
  // Scroll UP: quando está próximo do TOPO da área do ListView
  if (adjustedDy < edgeThreshold && adjustedDy > 0) {
    _startAutoScroll(-scrollSpeed);
  } 
  // Scroll DOWN: quando está próximo do FINAL da área do ListView
  else if (adjustedDy > listViewHeight - edgeThreshold && adjustedDy < listViewHeight) {
    _startAutoScroll(scrollSpeed);
  } 
  else {
    _stopAutoScroll();
  }
}

  // 🔥 Timer que verifica posição baseado em _lastDragX atualizado pelo Listener global
  void _startPositionCheckTimer() {
    _positionCheckTimer?.cancel();
    
    _positionCheckTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      final screenWidth = MediaQuery.of(context).size.width;
      const horizontalThreshold = 50.0;

      // Calcula direção desejada baseada na posição atual
      int desiredDirection = 0;
      if (_lastDragX < horizontalThreshold) {
        desiredDirection = -1;
      } else if (_lastDragX > screenWidth - horizontalThreshold) {
        desiredDirection = 1;
      }

      // Verifica se parou de mover
      bool stoppedMoving = false;
      if (_lastUpdateTime != null) {
        final timeSinceLastUpdate = DateTime.now().difference(_lastUpdateTime!).inMilliseconds;
        stoppedMoving = timeSinceLastUpdate > 300;
      }

      // Para APENAS se parou de mover E está FORA da zona
      if (stoppedMoving && desiredDirection == 0) {
        if (_activeDirection != 0) {
          _stopWeekChange();
          _activeDirection = 0;
        }
        return;
      }

      // Se a direção mudou, atualiza
      if (desiredDirection != _activeDirection) {
        if (desiredDirection != 0) {
          _startWeekChange(desiredDirection);
        } else {
          _stopWeekChange();
        }
        _activeDirection = desiredDirection;
      }
    });
  }

  void _stopPositionCheckTimer() {
    _positionCheckTimer?.cancel();
    _positionCheckTimer = null;
  }

  // 🔥 CORRIGIDO: Para o timer anterior antes de iniciar novo
  void _startWeekChange(int direction) {
    // 🔥 SEMPRE para o timer anterior primeiro
    _stopWeekChange();

    // Primeira mudança imediata
    _changeWeekImmediate(direction);

    // Timer que continua mudando
    _weekChangeTimer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      _changeWeekImmediate(direction);
    });
  }

  void _stopWeekChange() {
    _weekChangeTimer?.cancel();
    _weekChangeTimer = null;
  }

  void _changeWeekImmediate(int direction) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentWeekStart = _currentWeekStart.add(Duration(days: 7 * direction));
    });
    _loadWeeklyTasks();
  }

  void _startAutoScroll(double scrollDelta) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_scrollController.hasClients) {
        final newOffset = _scrollController.offset + scrollDelta;
        final maxScroll = _scrollController.position.maxScrollExtent;

        if (newOffset < 0) {
          _scrollController.jumpTo(0);
        } else if (newOffset > maxScroll) {
          _scrollController.jumpTo(maxScroll);
        } else {
          _scrollController.jumpTo(newOffset);
        }
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

@override
Widget build(BuildContext context) {
  return Listener(
    onPointerMove: (event) {
      // ✅ SÓ processa se estiver arrastando uma tarefa
      if (!_isDraggingTask) {
        return;
      }
      
      _lastDragX = event.position.dx;
      _lastUpdateTime = DateTime.now();
      
      final dy = event.position.dy;
      final screenHeight = MediaQuery.of(context).size.height;
      final topOffset = MediaQuery.of(context).padding.top + 8 + 8 + 52 + 50;
      
      const edgeThreshold = 100.0;
      const scrollSpeed = 10.0;
      
      final adjustedDy = dy - topOffset;
      final listViewHeight = screenHeight - topOffset;
      
      if (adjustedDy < edgeThreshold && adjustedDy > 0) {
        _startAutoScroll(-scrollSpeed);
      } else if (adjustedDy > listViewHeight - edgeThreshold && adjustedDy < listViewHeight) {
        _startAutoScroll(scrollSpeed);
      } else {
        _stopAutoScroll();
      }
    },
    child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color.fromARGB(255, 198, 162, 140).withValues(alpha: 0.9),
                const Color.fromARGB(255, 171, 168, 192),
              ],
            ),
          ),
          child: Column(
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
                    if (provider.isLoading && provider.weeklyTasks.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.errorMessage != null &&
                        provider.weeklyTasks.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: Colors.red),
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
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
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
        ),
      ),
    );
  }

  Widget _buildWeekSelector() {
  final weekEnd = _currentWeekStart.add(const Duration(days: 6));
  final weekNumber = _getWeekNumber();
  final weekStatus = _getWeekStatus();
  
  // 🔥 Cores seguindo o padrão da Daily View
  Color statusColor;
  if (weekStatus == 'Atual') {
    statusColor = AppConstants.primaryColor; // Azul igual ao botão "Hoje"
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
              _currentWeekStart =
                  _currentWeekStart.subtract(const Duration(days: 7));
            });
            _loadWeeklyTasks();
          },
        ),
        Expanded(
          child: Column(
            children: [
              // 🔥 Número da semana em preto (peso bold)
              Text(
                weekNumber,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black, // Preto igual às datas da Daily View
                ),
              ),
              // 🔥 Status e intervalo de datas em cinza
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekStatus,
                    style: TextStyle(
                      fontSize: 13,
                      color: statusColor, // Cor baseada no status
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    ' • ${DateFormat('dd/MM').format(_currentWeekStart)} - ${DateFormat('dd/MM').format(weekEnd)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600, // Cinza igual ao dia da semana
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (!_isCurrentWeek())
          IconButton(
            icon: const Icon(Icons.today),
            color: AppConstants.primaryColor, // Azul igual ao botão "Hoje"
            onPressed: () {
              setState(() {
                _currentWeekStart = DateTime.now().subtract(
                    Duration(days: DateTime.now().weekday - 1));
              });
              _loadWeeklyTasks();
            },
          ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            setState(() {
              _currentWeekStart =
                  _currentWeekStart.add(const Duration(days: 7));
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
        itemCount: allContexts.length + 1,
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
                selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                    color: _selectedContext == null
                        ? AppConstants.primaryColor
                        : Colors.grey.shade700),
                side: BorderSide(
                    color: _selectedContext == null
                        ? AppConstants.primaryColor
                        : Colors.grey.shade400),
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
              selectedColor: color.withValues(alpha: 0.2),
              labelStyle:
                  TextStyle(color: isSelected ? color : Colors.grey.shade700),
              side:
                  BorderSide(color: isSelected ? color : Colors.grey.shade400),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayCard(DateTime date, TaskProvider provider) {
    final dayTasks = provider.weeklyTasks.where((t) {
      final taskDate = DateTime(
          t.dateScheduled.year, t.dateScheduled.month, t.dateScheduled.day);
      final checkDate = DateTime(date.year, date.month, date.day);
      if (_selectedContext != null && t.contextTag != _selectedContext) {
        return false;
      }
      return taskDate.isAtSameMomentAs(checkDate);
    }).toList();

    dayTasks.sort((a, b) {
      final energyOrder = {
        EnergyLevel.highEnergy: 0,
        EnergyLevel.renewal: 1,
        EnergyLevel.lowEnergy: 2,
      };
      return energyOrder[a.energyLevel]!
          .compareTo(energyOrder[b.energyLevel]!);
    });

    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final availableHours = provider.weeklyConfigs[dateKey] ?? 8.0;
    final usedHours = provider.getUsedHours(date);
    final percentage = (usedHours / availableHours).clamp(0.0, 1.0);

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final task = details.data;
        final bool isRepeatable = task.isRepeatable == true;
        return !isRepeatable;
      },
      onAcceptWithDetails: (details) {
        final task = details.data;

        final taskCurrentDate = DateTime(task.dateScheduled.year,
            task.dateScheduled.month, task.dateScheduled.day);
        final targetDate = DateTime(date.year, date.month, date.day);

        if (taskCurrentDate.isAtSameMomentAs(targetDate)) {
          return;
        }

        if (!provider.canFitTask(date, task.durationMinutes)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${_getDayName(date)} está lotado!'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        }

        final index = provider.weeklyTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          final updatedTask = Task(
            id: task.id,
            title: task.title,
            energyLevel: task.energyLevel,
            durationMinutes: task.durationMinutes,
            status: task.status,
            dateScheduled: date,
            roleTag: task.roleTag,
            contextTag: task.contextTag,
            delegatedTo: task.delegatedTo,
            followUpDate: task.followUpDate,
            isRepeatable: task.isRepeatable,
            repeatCount: task.repeatCount,
            repeatDays: task.repeatDays,
            createdAt: task.createdAt,
            updatedAt: DateTime.now(),
          );

          provider.weeklyTasks[index] = updatedTask;

          if (mounted) {
            setState(() {});
          }
        }

        provider.moveTaskToDate(task.id, date).then((success) {
          if (success) {
            _loadWeeklyTasks();
          } else if (mounted) {
            _loadWeeklyTasks();
          }
        });

        HapticFeedback.mediumImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text('Movida para ${_getDayName(date)}'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color:
                candidateData.isNotEmpty ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  candidateData.isNotEmpty ? Colors.blue : Colors.grey.shade300,
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
                    Row(
                      children: [
                        Text(
                          '${_getDayName(date)}, ${DateFormat('dd/MM').format(date)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Text(
                      '${usedHours.toStringAsFixed(1)}h / ${availableHours.toStringAsFixed(1)}h',
                      style: TextStyle(
                        fontSize: 14,
                        color: percentage > 1.0
                            ? Colors.red
                            : Colors.grey.shade700,
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
              const SizedBox(height: 4),
              if (dayTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Text(
                    'Nenhuma tarefa para ${_getDayName(date)}.',
                    style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ...dayTasks.map((task) => _buildWeeklyTaskCard(task)),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  static const Color _doneTaskBackgroundColor = Color(0xFF8BC34A);

  Widget _buildRepeatSeriesBadge(Task task, bool isDone) {
    if (!task.isRepeatable) return const SizedBox.shrink();

    final n = task.repeatCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDone
            ? const Color.fromARGB(255, 226, 204, 230)
            : const Color.fromARGB(255, 226, 204, 230),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Text(
        '#$n',
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildWeeklyTaskCard(Task task) {
    final contextColor = ContextColors.getColor(task.contextTag);
    final isDone = task.status == TaskStatus.done;
    final activeBackgroundColor = task.energyLevel.color.withValues(alpha: 0.1);
    final activeBorderColor = task.energyLevel.color;
    final bool isRepeatable = task.isRepeatable == true;

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
        if (result == true && mounted) {
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

    if (isRepeatable) {
      return card;
    }

    return LongPressDraggable<Task>(
  data: task,
  delay: const Duration(milliseconds: 300),
  hapticFeedbackOnStart: true,
  onDragStarted: () {
    _isDraggingTask = true; // ✅ MARCA que está arrastando
    _activeDirection = 0;
    _lastDragX = 99999;
    _lastUpdateTime = null;
  },
  onDragUpdate: (details) {
    if (_positionCheckTimer == null || !_positionCheckTimer!.isActive) {
      _startPositionCheckTimer();
    }
    _handleDragUpdate(details);
  },
  onDragEnd: (details) {
    _isDraggingTask = false; // ✅ PARA o drag
    _activeDirection = 0;
    _lastUpdateTime = null;
    _stopPositionCheckTimer();
    _stopAutoScroll();
    _stopWeekChange();
  },
  onDragCompleted: () {
    _isDraggingTask = false; // ✅ PARA o drag
    _activeDirection = 0;
    _lastUpdateTime = null;
    _stopPositionCheckTimer();
    _stopAutoScroll();
    _stopWeekChange();
  },
  onDraggableCanceled: (velocity, offset) {
    _isDraggingTask = false; // ✅ PARA o drag
    _activeDirection = 0;
    _lastUpdateTime = null;
    _stopPositionCheckTimer();
    _stopAutoScroll();
    _stopWeekChange();
  },
      feedback: Material(
        elevation: 4.0,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDone
                ? _doneTaskBackgroundColor.withValues(alpha: 0.7)
                : activeBackgroundColor.withValues(alpha: 0.7),
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.all(8),
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

  Widget _buildWeeklyTaskCardContent(
    Task task,
    Color contextColor,
    bool isDone,
    Color activeBackgroundColor,
    Color activeBorderColor,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDone ? _doneTaskBackgroundColor : activeBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDone
              ? const Color.fromARGB(255, 110, 174, 36)
              : activeBorderColor,
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: isDone ? TextDecoration.lineThrough : null,
                    color: Colors.black87,
                  ),
                ),
                if (task.contextTag != null || task.roleTag != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      children: [
                        if (task.contextTag != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.label, size: 14, color: contextColor),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  task.contextTag!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: contextColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        if (task.roleTag != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person,
                                  size: 14, color: Colors.blue),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  task.roleTag!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (task.isRepeatable) _buildRepeatSeriesBadge(task, isDone),
              if (task.isRepeatable) const SizedBox(height: 3),
              Text(
                '${(task.durationMinutes / 60).toStringAsFixed(1)}h',
                style: TextStyle(
                  fontSize: 12,
                  color: isDone ? Colors.grey.shade900 : Colors.grey.shade700,
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