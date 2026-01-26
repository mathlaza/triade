import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/providers/config_provider.dart';
import 'package:triade_app/widgets/progress_bar.dart';
import 'package:triade_app/screens/add_task_screen.dart';
import 'package:triade_app/screens/pending_review_modal.dart';
import 'package:triade_app/config/constants.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/models/daily_summary.dart';
import 'package:triade_app/widgets/daily/daily_widgets.dart';
import 'package:triade_app/services/sound_service.dart';

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
  int get hashCode =>
      Object.hash(isLoading, tasks.length, summary, errorMessage);
}

class DailyViewScreen extends StatefulWidget {
  const DailyViewScreen({super.key});

  @override
  State<DailyViewScreen> createState() => DailyViewScreenState();
}

class DailyViewScreenState extends State<DailyViewScreen>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Mantém estado quando muda de aba

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
        builder: (context) => PendingReviewModal(
          tasks: pendingTasks,
          pendingDate: yesterday, // ✅ Passa a data de pendência
        ),
      );
      
      // ✅ Após fechar o modal, recarrega os dados para refletir mudanças
      if (mounted) {
        _loadData();
      }
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final configProvider = context.read<ConfigProvider>();
    final taskProvider = context.read<TaskProvider>();
    await configProvider.loadDailyConfig(selectedDate);
    await taskProvider.loadDailyTasks(selectedDate);
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

  Future<void> _updateDailyHours(double hours) async {
    if (!mounted) return;

    final configProvider = context.read<ConfigProvider>();
    final taskProvider = context.read<TaskProvider>();

    final success = await configProvider.setDailyConfig(selectedDate, hours);

    if (success && mounted) {
      // Reload to update the UI with new hours
      await taskProvider.loadDailyTasks(selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF000000), // Preto puro como iOS
        ),
        child: Column(
          children: [
            const DailyHeader(),
            DailyDateSelector(
              selectedDate: selectedDate,
              isToday: _isToday(),
              isFutureDate: _isFutureDate(),
              onPreviousDay: () => _changeDate(
                selectedDate.subtract(const Duration(days: 1)),
                isNext: false,
              ),
              onNextDay: () => _changeDate(
                selectedDate.add(const Duration(days: 1)),
                isNext: true,
              ),
              onTodayTap: () {
                final today = DateTime.now();
                final isNext = selectedDate.isBefore(today);
                _changeDate(today, isNext: isNext);
              },
              onDateSelected: (date) {
                _changeDate(date, isNext: date.isAfter(selectedDate));
              },
            ),
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
                              onHoursTap: () => HoursPickerModal.show(
                                context,
                                currentHours: data.summary!.availableHours,
                                selectedDate: selectedDate,
                                onSave: _updateDailyHours,
                              ),
                            ),
                          DailyTaskSection(
                            title: '🧠 Alta Energia',
                            tasks: data.highEnergyTasks,
                            energyColor: EnergyLevel.highEnergy.color,
                            selectedDate: selectedDate,
                            onDataChanged: _loadData,
                          ),
                          DailyTaskSection(
                            title: '🔋 Renovação',
                            tasks: data.renewalTasks,
                            energyColor: EnergyLevel.renewal.color,
                            selectedDate: selectedDate,
                            onDataChanged: _loadData,
                          ),
                          DailyTaskSection(
                            title: '🌙 Baixa Energia',
                            tasks: data.lowEnergyTasks,
                            energyColor: EnergyLevel.lowEnergy.color,
                            selectedDate: selectedDate,
                            onDataChanged: _loadData,
                          ),
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
      floatingActionButton: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.5),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            SoundService().playClick();
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
}
