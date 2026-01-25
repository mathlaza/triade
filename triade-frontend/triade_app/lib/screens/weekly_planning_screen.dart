import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/screens/add_task_screen.dart';
import 'package:triade_app/widgets/user_avatar_menu.dart';
import 'package:triade_app/widgets/weekly/weekly_widgets.dart';

// Premium Dark Theme Colors
const _kBackgroundColor = Color(0xFF000000);
const _kSurfaceColor = Color(0xFF1C1C1E);
const _kCardColor = Color(0xFF2C2C2E);
const _kBorderColor = Color(0xFF38383A);
const _kGoldAccent = Color(0xFFFFD60A);
const _kTextPrimary = Color(0xFFFFFFFF);
const _kTextSecondary = Color(0xFF8E8E93);

class _WeeklyViewData {
  final bool isLoading;
  final List<Task> weeklyTasks;
  final Map<String, double> weeklyConfigs;
  final String? errorMessage;
  final int _tasksHash; // ✅ Hash que detecta mudanças no conteúdo

  _WeeklyViewData({
    required this.isLoading,
    required this.weeklyTasks,
    required this.weeklyConfigs,
    required this.errorMessage,
  }) : _tasksHash = _computeTasksHash(weeklyTasks);
  
  /// ✅ Computa hash baseado no status de cada tarefa
  static int _computeTasksHash(List<Task> tasks) {
    if (tasks.isEmpty) return 0;
    return Object.hashAll(tasks.map((t) => '${t.id}_${t.status.name}'));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _WeeklyViewData &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          _tasksHash == other._tasksHash &&
          weeklyConfigs.length == other.weeklyConfigs.length &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
      isLoading, _tasksHash, weeklyConfigs.length, errorMessage);
}

class WeeklyPlanningScreen extends StatefulWidget {
  const WeeklyPlanningScreen({super.key});

  @override
  State<WeeklyPlanningScreen> createState() => WeeklyPlanningScreenState();
}

class WeeklyPlanningScreenState extends State<WeeklyPlanningScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Mantém estado quando muda de aba

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

  // ✅ Animação para troca de semana (igual ao Daily View)
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void onBecameVisible() {
    _stopAutoScroll();
    _stopWeekChange();
    _stopPositionCheckTimer();
    _loadWeeklyTasks();
  }

  @override
  void dispose() {
    _animationController.dispose();
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

  // Atualiza a posição E registra timestamp
  void _handleDragUpdate(DragUpdateDetails details) {
    final screenHeight = MediaQuery.of(context).size.height;
    final dy = details.globalPosition.dy;
    final dx = details.globalPosition.dx;

    _lastDragX = dx;
    _lastUpdateTime = DateTime.now();

    // ✅ CORREÇÃO: Calcula o offset do topo (AppBar + WeekSelector + ContextFilters)
    final topOffset = MediaQuery.of(context).padding.top +
        8 +
        8 +
        52 +
        50; // AppBar + margins + selector + filters

    const edgeThreshold = 100.0;
    const scrollSpeed = 20.0;

    // Ajusta dy para considerar apenas a área do ListView
    final adjustedDy = dy - topOffset;
    final listViewHeight = screenHeight - topOffset;

    // Scroll UP: quando está próximo do TOPO da área do ListView
    if (adjustedDy < edgeThreshold && adjustedDy > 0) {
      _startAutoScroll(-scrollSpeed);
    }
    // Scroll DOWN: quando está próximo do FINAL da área do ListView
    else if (adjustedDy > listViewHeight - edgeThreshold &&
        adjustedDy < listViewHeight) {
      _startAutoScroll(scrollSpeed);
    } else {
      _stopAutoScroll();
    }
  }

  // 🔥 Timer que verifica posição baseado em _lastDragX atualizado pelo Listener global
  void _startPositionCheckTimer() {
    _positionCheckTimer?.cancel();

    _positionCheckTimer =
        Timer.periodic(const Duration(milliseconds: 150), (timer) {
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
        final timeSinceLastUpdate =
            DateTime.now().difference(_lastUpdateTime!).inMilliseconds;
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
    _weekChangeTimer =
        Timer.periodic(const Duration(milliseconds: 900), (timer) {
      _changeWeekImmediate(direction);
    });
  }

  void _stopWeekChange() {
    _weekChangeTimer?.cancel();
    _weekChangeTimer = null;
  }

  void _changeWeekImmediate(int direction) {
    _animateWeekChange(direction);
  }

  // ✅ Animação suave ao trocar de semana
  void _animateWeekChange(int direction) {
    HapticFeedback.lightImpact();

    // ✅ Direção corrigida: avançar = sair para esquerda, voltar = sair para direita
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(-direction.toDouble(), 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward().then((_) {
      setState(() {
        _currentWeekStart =
            _currentWeekStart.add(Duration(days: 7 * direction));
      });

      _slideAnimation = Tween<Offset>(
        begin: Offset(direction.toDouble(), 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      _animationController.reset();
      _animationController.forward();
      _loadWeeklyTasks();
    });
  }

  // Método para troca de semana sem animação (botões)
  void _changeWeekWithAnimation(int direction) {
    HapticFeedback.lightImpact();
    _animateWeekChange(direction);
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
    super.build(context); // ✅ Required for AutomaticKeepAliveClientMixin

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
        const scrollSpeed = 20.0;

        final adjustedDy = dy - topOffset;
        final listViewHeight = screenHeight - topOffset;

        if (adjustedDy < edgeThreshold && adjustedDy > 0) {
          _startAutoScroll(-scrollSpeed);
        } else if (adjustedDy > listViewHeight - edgeThreshold &&
            adjustedDy < listViewHeight) {
          _startAutoScroll(scrollSpeed);
        } else {
          _stopAutoScroll();
        }
      },
      child: Scaffold(
        backgroundColor: _kBackgroundColor,
        body: Column(
          children: [
            // Premium Header - igual ao Daily View
            Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 12,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: _kSurfaceColor,
                border: Border(
                  bottom: BorderSide(
                    color: _kBorderColor.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Espaço vazio à esquerda (mesmo tamanho do ícone direito)
                  const SizedBox(
                      width: 42), // 8 padding + 18 icon + 8 padding + 8 extra
                  // Centro expandido
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: OverflowBox(
                            maxWidth: 48,
                            maxHeight: 48,
                            child: Image.asset(
                              'assets/logo_nobg.png',
                              width: 48,
                              height: 48,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Semanal',
                          style: TextStyle(
                            color: _kTextPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar do usuário à direita
                  const UserAvatarMenu(
                    radius: 20,
                    backgroundColor: _kCardColor,
                    showBorder: true,
                    borderColor: _kGoldAccent,
                  ),
                ],
              ),
            ),
            WeekSelectorWidget(
              currentWeekStart: _currentWeekStart,
              isCurrentWeek: _isCurrentWeek(),
              onPreviousWeek: () => _changeWeekWithAnimation(-1),
              onNextWeek: () => _changeWeekWithAnimation(1),
              onGoToCurrentWeek: () {
                setState(() {
                  _currentWeekStart = DateTime.now()
                      .subtract(Duration(days: DateTime.now().weekday - 1));
                });
                _loadWeeklyTasks();
              },
            ),
            ContextFiltersBar(
              selectedContext: _selectedContext,
              onContextSelected: (context) {
                setState(() {
                  _selectedContext = context;
                });
                _loadWeeklyTasks();
              },
            ),
            Expanded(
              child: Selector<TaskProvider, _WeeklyViewData>(
                selector: (_, provider) => _WeeklyViewData(
                  isLoading: provider.isLoading,
                  weeklyTasks: provider.weeklyTasks,
                  weeklyConfigs: provider.weeklyConfigs,
                  errorMessage: provider.errorMessage,
                ),
                shouldRebuild: (prev, next) => prev != next,
                builder: (context, data, child) {
                  if (data.isLoading && data.weeklyTasks.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: _kGoldAccent,
                      ),
                    );
                  }

                  if (data.errorMessage != null && data.weeklyTasks.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Color(0xFFFF453A)),
                          const SizedBox(height: 16),
                          Text(
                            data.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFFF453A)),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadWeeklyTasks,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kGoldAccent,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Tentar Novamente'),
                          ),
                        ],
                      ),
                    );
                  }

                  return SlideTransition(
                    position: _slideAnimation,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 12, bottom: 20),
                      itemCount: 7,
                      itemBuilder: (context, index) {
                        final date =
                            _currentWeekStart.add(Duration(days: index));
                        return _buildDayCard(date, data);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(DateTime date, _WeeklyViewData data) {
    final dayTasks = data.weeklyTasks.where((t) {
      final taskDate = DateTime(
          t.dateScheduled.year, t.dateScheduled.month, t.dateScheduled.day);
      final checkDate = DateTime(date.year, date.month, date.day);
      if (_selectedContext != null && t.contextTag != _selectedContext) {
        return false;
      }
      return taskDate.isAtSameMomentAs(checkDate);
    }).toList();

    dayTasks.sort((a, b) {
      // 1. Primeiro ordena por tipo de energia
      final energyOrder = {
        EnergyLevel.highEnergy: 0,
        EnergyLevel.renewal: 1,
        EnergyLevel.lowEnergy: 2,
      };
      final energyComparison =
          energyOrder[a.energyLevel]!.compareTo(energyOrder[b.energyLevel]!);
      if (energyComparison != 0) return energyComparison;

      // 2. Dentro do mesmo tipo de energia, ordena por horário (mais cedo primeiro)
      final aHasTime = a.scheduledTime != null;
      final bHasTime = b.scheduledTime != null;

      if (aHasTime && !bHasTime) return -1;
      if (!aHasTime && bHasTime) return 1;

      if (aHasTime && bHasTime) {
        final timeComparison = a.scheduledTime!.compareTo(b.scheduledTime!);
        if (timeComparison != 0) return timeComparison;
      }

      // 3. Empate: ordena por contexto
      final aContext = a.contextTag ?? '';
      final bContext = b.contextTag ?? '';
      return aContext.compareTo(bContext);
    });

    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final availableHours = data.weeklyConfigs[dateKey] ?? 8.0;
    final dayTasksForHours = data.weeklyTasks.where((t) {
      final taskDate = DateTime(
          t.dateScheduled.year, t.dateScheduled.month, t.dateScheduled.day);
      final checkDate = DateTime(date.year, date.month, date.day);
      return taskDate.isAtSameMomentAs(checkDate);
    }).toList();

    final totalMinutes = dayTasksForHours.fold<int>(
        0, (sum, task) => sum + task.durationMinutes);
    final usedHours = totalMinutes / 60.0;
    final percentage = (usedHours / availableHours).clamp(0.0, 1.0);

    return DragTarget<Task>(
      onWillAcceptWithDetails: (details) {
        final task = details.data;
        final bool isRepeatable = task.isRepeatable == true;
        return !isRepeatable;
      },
      onAcceptWithDetails: (details) {
        final task = details.data;
        final provider = context.read<TaskProvider>();

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
        final isToday = DateTime.now().year == date.year &&
            DateTime.now().month == date.month &&
            DateTime.now().day == date.day;
        final isReceiving = candidateData.isNotEmpty;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                isReceiving ? _kGoldAccent.withValues(alpha: 0.1) : _kCardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isReceiving
                  ? _kGoldAccent
                  : isToday
                      ? _kGoldAccent.withValues(alpha: 0.5)
                      : _kBorderColor,
              width: isReceiving || isToday ? 1.5 : 1,
            ),
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: _kGoldAccent.withValues(alpha: 0.15),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            children: [
              // Header do dia
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isToday
                      ? _kGoldAccent.withValues(alpha: 0.08)
                      : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(15),
                    topRight: Radius.circular(15),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (isToday)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: _kGoldAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          '${_getDayName(date)}, ${DateFormat('dd/MM').format(date)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isToday ? _kGoldAccent : _kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: percentage > 1.0
                            ? const Color(0xFFFF453A).withValues(alpha: 0.15)
                            : _kSurfaceColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${usedHours.toStringAsFixed(1)}h / ${availableHours.toStringAsFixed(1)}h',
                        style: TextStyle(
                          fontSize: 12,
                          color: percentage > 1.0
                              ? const Color(0xFFFF453A)
                              : _kTextSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Progress bar
              Container(
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: _kBorderColor,
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: percentage,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: percentage > 1.0
                          ? const Color(0xFFFF453A)
                          : _kGoldAccent,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              if (dayTasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Nenhuma tarefa',
                    style: TextStyle(
                      color: _kTextSecondary.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
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

  // Task done background - verde suave para modo escuro
  // ✅ Cor diferenciada para done - Azul suave (diferente de Renovação verde)
  static const Color _doneTaskBackgroundColor = Color(0xFF64D2FF); // Azul iOS

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
      child: WeeklyTaskCardContent(
        task: task,
        contextColor: contextColor,
        isDone: isDone,
        activeBackgroundColor: activeBackgroundColor,
        activeBorderColor: activeBorderColor,
      ),
    );

    if (isRepeatable) {
      return card;
    }

    return LongPressDraggable<Task>(
      data: task,
      delay: const Duration(milliseconds: 300),
      hapticFeedbackOnStart: false,
      onDragStarted: () {
        HapticFeedback.lightImpact();
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
        HapticFeedback.lightImpact();
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
        elevation: 8.0,
        borderRadius: BorderRadius.circular(10),
        color: Colors.transparent,
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDone
                ? _doneTaskBackgroundColor.withValues(alpha: 0.9)
                : _kSurfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDone ? _doneTaskBackgroundColor : activeBorderColor,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDone ? _doneTaskBackgroundColor : activeBorderColor)
                    .withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Text(
            task.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              decoration: isDone ? TextDecoration.lineThrough : null,
              color: isDone ? Colors.black87 : _kTextPrimary,
            ),
          ),
        ),
      ),
      childWhenDragging: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _kBorderColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kBorderColor, width: 1),
        ),
        child: Opacity(
          opacity: 0.4,
          child: WeeklyTaskCardContent(
            task: task,
            contextColor: contextColor,
            isDone: isDone,
            activeBackgroundColor: activeBackgroundColor,
            activeBorderColor: activeBorderColor,
          ),
        ),
      ),
      child: card,
    );
  }

  String _getDayName(DateTime date) {
    const days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return days[date.weekday - 1];
  }
}
