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

class DailyViewScreen extends StatefulWidget {
  const DailyViewScreen({super.key});

  @override
  State<DailyViewScreen> createState() => DailyViewScreenState();
}

class DailyViewScreenState extends State<DailyViewScreen> with SingleTickerProviderStateMixin {
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
    final selected = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    return selected.isAfter(today);
  }

  bool _isToday() {
    final now = DateTime.now();
    return selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;
  }


Future<void> _changeDate(DateTime newDate, {bool isNext = true}) async {
  // Carregar dados PRIMEIRO (em background)
  final loadFuture = Future.microtask(() async {
    if (!mounted) return;
    await context.read<ConfigProvider>().loadDailyConfig(newDate);
    await context.read<TaskProvider>().loadDailyTasks(newDate);
  });
  
  // Animar saída
  setState(() {
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(isNext ? -0.3 : 0.3, 0), // Movimento menor = mais rápido
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
  });
  
  await _animationController.forward(from: 0.0);
  
  // Mudar data
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
  
  await _animationController.forward(from: 0.0);
  
  // Aguardar dados carregarem (se ainda não terminou)
  await loadFuture;
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
                child: Consumer<TaskProvider>(
                  builder: (context, provider, child) {
                  if (provider.isLoading && provider.tasks.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFD700),
                      ),
                    );
                  }

                  if (provider.errorMessage != null && provider.tasks.isEmpty) {
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
                          Icon(Icons.event_available, size: 64, color: Colors.grey[700]),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma tarefa para este dia',
                            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
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
                        if (provider.summary != null)
                          DailyProgressBar(
                            usedHours: provider.summary!.usedHours,
                            availableHours: provider.summary!.availableHours,
                            highEnergyHours: _calculateCompletedHoursByEnergy(
                              provider.tasks, EnergyLevel.highEnergy),
                            renewalHours: _calculateCompletedHoursByEnergy(
                              provider.tasks, EnergyLevel.renewal),
                            lowEnergyHours: _calculateCompletedHoursByEnergy(
                              provider.tasks, EnergyLevel.lowEnergy),
                          ),
                        _buildTaskSection('🧠 Alta Energia', provider.highEnergyTasks),
                        _buildTaskSection('🔋 Renovação', provider.renewalTasks),
                        _buildTaskSection('⚡ Baixa Energia', provider.lowEnergyTasks),
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
      floatingActionButton: FloatingActionButton.extended(
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
        icon: const Icon(Icons.add, color: Color(0xFF0A0E1A)),
        label: const Text(
          'Nova Tarefa',
          style: TextStyle(
            color: Color(0xFF0A0E1A),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: const Color(0xFFFFD700),
        elevation: 8,
      ),
    );
  }

  double _calculateCompletedHoursByEnergy(List tasks, EnergyLevel level) {
    return tasks
        .where((t) => t.energyLevel == level && t.status == TaskStatus.done)
        .fold(0.0, (sum, t) => sum + (t.durationMinutes / 60));
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
        SizedBox(width: 42), // 8 padding + 18 icon + 8 padding + 8 extra
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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

Widget _buildNavButton({required IconData icon, required VoidCallback onTap}) {
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

  Widget _buildTaskSection(String title, List tasks) {
    if (tasks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.5,
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