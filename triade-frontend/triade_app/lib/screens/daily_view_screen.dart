import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/providers/config_provider.dart';
import 'package:triade_app/widgets/task_card.dart';
import 'package:triade_app/widgets/progress_bar.dart';
import 'package:triade_app/screens/add_task_screen.dart';
import 'package:triade_app/screens/pending_review_modal.dart';
import 'package:triade_app/config/constants.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/models/daily_summary.dart';


class _DailyViewData {
  final bool isLoading;
  final List<Task> tasks;
  final DailySummary? summary;
  final String? errorMessage;
  final List<Task> highEnergyTasks;
  final List<Task> renewalTasks;
  final List<Task> lowEnergyTasks;
  final double highEnergyHours;
  final double renewalHours;
  final double lowEnergyHours;

  _DailyViewData({
    required this.isLoading,
    required this.tasks,
    required this.summary,
    required this.errorMessage,
    required this.highEnergyTasks,
    required this.renewalTasks,
    required this.lowEnergyTasks,
    required this.highEnergyHours,
    required this.renewalHours,
    required this.lowEnergyHours,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _DailyViewData &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          tasks.length == other.tasks.length &&
          summary == other.summary &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(isLoading, tasks.length, summary, errorMessage);
}


class DailyViewScreen extends StatefulWidget {
  const DailyViewScreen({super.key});

  @override
  State<DailyViewScreen> createState() => DailyViewScreenState();
}

class DailyViewScreenState extends State<DailyViewScreen>
    with SingleTickerProviderStateMixin {
  DateTime selectedDate = DateTime.now();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);

    // Configurar animação
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200), // Mais rápido!
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkPendingReview();
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void onBecameVisible() {
    _loadData();
  }

  Future<void> _checkPendingReview() async {
    if (!mounted) return;

    final provider = context.read<TaskProvider>();
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final pendingTasks = await provider.getPendingReview(yesterday);

    if (pendingTasks.isNotEmpty && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PendingReviewModal(tasks: pendingTasks),
      );
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    await context.read<ConfigProvider>().loadDailyConfig(selectedDate);
    await context.read<TaskProvider>().loadDailyTasks(selectedDate);
  }

  bool _isFutureDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return selected.isAfter(today);
  }

  bool _isToday() {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }

Future<void> _changeDate(DateTime newDate, {bool isNext = true}) async {
  // ✅ Animar saída IMEDIATAMENTE
  setState(() {
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(isNext ? -0.3 : 0.3, 0),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  });

  _animationController.forward(from: 0.0);

  // ✅ Mudar data instantaneamente (cache mostra dados antigos)
  setState(() {
    selectedDate = newDate;
    _slideAnimation = Tween<Offset>(
      begin: Offset(isNext ? 0.3 : -0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  });

  _animationController.forward(from: 0.0);

  // ✅ Carrega dados em background (não bloqueia UI)
  if (!mounted) return;
  context.read<ConfigProvider>().loadDailyConfig(newDate);
  context.read<TaskProvider>().loadDailyTasks(newDate);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF000000), // Preto puro como iOS
        ),
        child: Column(
          children: [
            _buildModernHeader(),
            _buildElegantDateSelector(),
Expanded(
  child: SlideTransition(
    position: _slideAnimation,
    child: Selector<TaskProvider, _DailyViewData>(
      selector: (_, provider) => _DailyViewData(
        isLoading: provider.isLoading,
        tasks: provider.tasks,
        summary: provider.summary,
        errorMessage: provider.errorMessage,
        highEnergyTasks: provider.highEnergyTasks,
        renewalTasks: provider.renewalTasks,
        lowEnergyTasks: provider.lowEnergyTasks,
        highEnergyHours: provider.highEnergyCompletedHours,
        renewalHours: provider.renewalCompletedHours,
        lowEnergyHours: provider.lowEnergyCompletedHours,
      ),
      shouldRebuild: (prev, next) => prev != next,
      builder: (context, data, child) {
        if (data.isLoading && data.tasks.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFD700),
            ),
          );
        }

        if (data.errorMessage != null && data.tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  data.errorMessage!,
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

        if (data.tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available,
                    size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  'Nenhuma tarefa para este dia',
                  style: TextStyle(
                      fontSize: 16, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _loadData,
          color: const Color(0xFFFFD700),
          child: ListView(
            padding: const EdgeInsets.only(top: 0, bottom: 10),
            children: [
              if (data.summary != null)
                DailyProgressBar(
                  usedHours: data.summary!.usedHours,
                  availableHours: data.summary!.availableHours,
                  highEnergyHours: data.highEnergyHours,
                  renewalHours: data.renewalHours,
                  lowEnergyHours: data.lowEnergyHours,
                ),
              _buildTaskSection(
                  '🧠 Alta Energia',
                  data.highEnergyTasks,
                  EnergyLevel.highEnergy.color),
              _buildTaskSection('🔋 Renovação',
                  data.renewalTasks, EnergyLevel.renewal.color),
              _buildTaskSection(
                  '🌙 Baixa Energia',
                  data.lowEnergyTasks,
                  EnergyLevel.lowEnergy.color),
              const SizedBox(height: 80),
            ],
          ),
        );
      },
    ),
  ),
),
          ],
        ),
      ),
      floatingActionButton: SizedBox(
        width: 50,
        height: 50,
        child: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddTaskScreen(selectedDate: selectedDate),
              ),
            );
            if (result == true && mounted) {
              _loadData();
            }
          },
          backgroundColor: const Color(0xFFFFD700),
          elevation: 8,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Color(0xFF0A0E1A), size: 28),
        ),
      ),
    );
  }


  Widget _buildModernHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 12,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF38383A).withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Espaço vazio à esquerda (mesmo tamanho do ícone direito)
          const SizedBox(width: 42), // 8 padding + 18 icon + 8 padding + 8 extra
          // Centro expandido
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD60A), Color(0xFFFFCC00)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.diamond,
                    color: Color(0xFF000000),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Tríade',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Ícone de ajustes à direita
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.tune,
              color: Color(0xFFFFD60A),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElegantDateSelector() {
    final weekday = DateFormat('EEEE', 'pt_BR').format(selectedDate);
    final weekdayCapitalized = weekday[0].toUpperCase() + weekday.substring(1);
    final isToday = _isToday();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF38383A),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavButton(
            icon: Icons.chevron_left_rounded,
            onTap: () => _changeDate(
              selectedDate.subtract(const Duration(days: 1)),
              isNext: false,
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                          primary: Color(0xFFFFD60A),
                          surface: Color(0xFF1C1C1E),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
                if (date != null && mounted) {
                  _changeDate(date, isNext: date.isAfter(selectedDate));
                }
              },
              child: Column(
                children: [
                  Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        weekdayCapitalized,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF98989D),
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (!isToday) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (_isFutureDate()
                                ? const Color(0xFFFF9F0A)
                                : const Color(0xFF636366)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _isFutureDate() ? 'Futuro' : 'Passado',
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF000000),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isToday)
            _buildNavButton(
              icon: Icons.chevron_right_rounded,
              onTap: () => _changeDate(
                selectedDate.add(const Duration(days: 1)),
                isNext: true,
              ),
            )
          else
            Row(
              children: [
                _buildTodayButton(),
                const SizedBox(width: 6),
                _buildNavButton(
                  icon: Icons.chevron_right_rounded,
                  onTap: () => _changeDate(
                    selectedDate.add(const Duration(days: 1)),
                    isNext: true,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildNavButton(
      {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF98989D), size: 20),
      ),
    );
  }

  Widget _buildTodayButton() {
    return InkWell(
      onTap: () {
        final today = DateTime.now();
        final isNext = selectedDate.isBefore(today);
        _changeDate(today, isNext: isNext);
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(right: 10.0),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD60A),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.today, size: 12, color: Color(0xFF000000)),
            SizedBox(width: 4),
            Text(
              'Hoje',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF000000),
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskSection(String title, List tasks, Color energyColor) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 160,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 1),
          padding: const EdgeInsets.fromLTRB(4, 1.5, 12, 1.5),
          decoration: BoxDecoration(
            color: energyColor.withValues(alpha: 0.60),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: energyColor.withValues(alpha: 0.8),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.3,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
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
            onLongPress: () async {
              HapticFeedback.mediumImpact();
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
                _loadData();
              }
            },
            onDelete: deleteCb,
            onToggleDone: () async {
              HapticFeedback.lightImpact();
              await provider.toggleTaskDone(task.id);
            },
          );

          if (!task.isRepeatable) return card;

          return Dismissible(
            key: ValueKey(
                'task_${task.id}_${task.dateScheduled.toIso8601String()}'),
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
