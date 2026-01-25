import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/config/constants.dart';

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

  // Constantes de design - Dark Premium Theme
  static const Color _backgroundColor = Color(0xFF000000);
  static const Color _surfaceColor = Color(0xFF1C1C1E);
  static const Color _cardColor = Color(0xFF2C2C2E);
  static const Color _borderColor = Color(0xFF38383A);
  static const Color _accentGold = Color(0xFFFFD60A);
  static const Color _accentOrange = Color(0xFFFFA500);
  static const Color _textPrimary = Color(0xFFFFFFFF);
  static const Color _textSecondary = Color(0xFF8E8E93);
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
          _buildPremiumHeader(),
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
                  return _buildLoadingState();
                }

                if (data.errorMessage != null && data.delegatedTasks.isEmpty) {
                  return _buildErrorState(data.errorMessage!);
                }

                if (data.delegatedTasks.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildContent(data.delegatedTasks);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _surfaceColor,
            _surfaceColor.withValues(alpha: 0.95),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: _borderColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 16,
        left: 20,
        right: 16,
      ),
      child: Row(
        children: [
          // Botão de voltar
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor, width: 1),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Ícone decorativo
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accentGold, _accentOrange],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _accentGold.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.people_rounded,
              color: Colors.black,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Título
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tarefas Delegadas',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Acompanhe suas delegações',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _borderColor),
            ),
            child: const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: _accentGold,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Carregando delegações...',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _errorRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _errorRed.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: _errorRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _loadDelegatedTasks();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_accentGold, _accentOrange],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _accentGold.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Text(
                  'Tentar Novamente',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accentGold.withValues(alpha: 0.15),
                    _accentOrange.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: _accentGold.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 56,
                color: _accentGold.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Sem delegações ativas',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tarefas delegadas aparecerão aqui\npara você acompanhar',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(List<Task> delegatedTasks) {
    final overdue = <Task>[];
    final today = <Task>[];
    final upcoming = <Task>[];
    final noDate = <Task>[];

    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    for (var task in delegatedTasks) {
      if (task.followUpDate == null) {
        noDate.add(task);
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

    return RefreshIndicator(
      onRefresh: _loadDelegatedTasks,
      color: _accentGold,
      backgroundColor: _surfaceColor,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildStatsCard(delegatedTasks.length, overdue.length, today.length),
          if (overdue.isNotEmpty)
            _buildSection('Atrasadas', overdue, _errorRed, Icons.warning_rounded),
          if (today.isNotEmpty)
            _buildSection('Follow-up Hoje', today, _warningOrange, Icons.today_rounded),
          if (upcoming.isNotEmpty)
            _buildSection('Próximas', upcoming, _successGreen, Icons.event_rounded),
          if (noDate.isNotEmpty)
            _buildSection('Sem Data', noDate, _textSecondary, Icons.calendar_today_outlined),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStatsCard(int total, int overdue, int todayCount) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _surfaceColor,
            _cardColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _buildStatItem(Icons.forward_rounded, 'Delegadas', total.toString(), _accentGold)),
          Container(width: 1, height: 50, color: _borderColor),
          Expanded(child: _buildStatItem(Icons.warning_rounded, 'Atrasadas', overdue.toString(), overdue > 0 ? _errorRed : _textSecondary)),
          Container(width: 1, height: 50, color: _borderColor),
          Expanded(child: _buildStatItem(Icons.today_rounded, 'Hoje', todayCount.toString(), todayCount > 0 ? _warningOrange : _textSecondary)),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '${tasks.length}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...sortedTasks.map((task) => _buildDelegatedTaskCard(task, color, context)),
      ],
    );
  }

  Widget _buildDelegatedTaskCard(Task task, Color statusColor, BuildContext context) {
    final bool isCompleted = task.status == TaskStatus.done;
    
    return Dismissible(
      key: Key('delegated_task_${task.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        final confirmed = await _showReassignConfirmDialog(task);
        if (confirmed) {
          // Remove imediatamente da lista local ANTES de chamar a API
          await _reassignTask(task);
        }
        // Retorna false para não tentar remover novamente (já removemos manualmente)
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2C2C2E), Color(0xFFFFD60A)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            const Text(
              'Reassumir',
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.undo_rounded,
                color: Colors.black,
                size: 20,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isCompleted ? _successGreen.withValues(alpha: 0.15) : _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted ? _successGreen.withValues(alpha: 0.4) : _borderColor,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted 
                  ? _successGreen.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com energia e status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getEnergyColor(task.energyLevel).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getEnergyColor(task.energyLevel).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      task.energyLevel.label.toUpperCase(),
                      style: TextStyle(
                        color: _getEnergyColor(task.energyLevel),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Indicador de status
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _successGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: _successGreen),
                          SizedBox(width: 4),
                          Text(
                            'Concluída',
                            style: TextStyle(
                              color: _successGreen,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.5),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Row com checkbox e título
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Checkbox premium
                  GestureDetector(
                    onTap: () => _toggleTaskCompletion(task),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? const LinearGradient(
                                colors: [_successGreen, Color(0xFF28A745)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isCompleted ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCompleted ? _successGreen : _textSecondary,
                          width: 2,
                        ),
                        boxShadow: isCompleted
                            ? [
                                BoxShadow(
                                  color: _successGreen.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Título da tarefa
                  Expanded(
                    child: Text(
                      task.title,
                      style: TextStyle(
                        color: isCompleted ? _textSecondary : _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                        decorationColor: _textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Info de delegação
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isCompleted ? _successGreen.withValues(alpha: 0.1) : _cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCompleted ? _successGreen.withValues(alpha: 0.2) : _borderColor,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: isCompleted
                            ? LinearGradient(
                                colors: [_successGreen, _successGreen.withValues(alpha: 0.7)],
                              )
                            : const LinearGradient(
                                colors: [_accentGold, _accentOrange],
                              ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isCompleted ? Icons.check_rounded : Icons.person_outline_rounded,
                        size: 14,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delegada para',
                            style: TextStyle(
                              color: isCompleted ? _successGreen.withValues(alpha: 0.7) : _textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            task.delegatedTo ?? 'N/A',
                            style: TextStyle(
                              color: isCompleted ? _successGreen : _textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isCompleted ? _successGreen : statusColor).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: (isCompleted ? _successGreen : statusColor).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: isCompleted ? _successGreen : statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            task.followUpDate != null
                                ? DateFormat('dd/MM').format(task.followUpDate!)
                                : 'Sem data',
                            style: TextStyle(
                              fontSize: 12,
                              color: isCompleted ? _successGreen : statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Hint de swipe (só se não estiver concluída)
              if (!isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        Icons.swipe_left_rounded,
                        size: 14,
                        color: _textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Deslize para reassumir',
                        style: TextStyle(
                          color: _textSecondary.withValues(alpha: 0.5),
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _showReassignConfirmDialog(Task task) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: _borderColor),
        ),
        title: const Row(
          children: [
            Icon(Icons.undo_rounded, color: _accentGold, size: 24),
            SizedBox(width: 12),
            Text(
              'Reassumir Tarefa?',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _borderColor),
              ),
              child: Row(
                children: [
                  const Icon(Icons.task_alt_rounded, color: _accentGold, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Esta tarefa voltará para sua lista e será removida das delegações.',
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: _textSecondary),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.undo_rounded, size: 18),
            label: const Text('Reassumir', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    return result ?? false;
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

  Color _getEnergyColor(EnergyLevel energy) {
    switch (energy) {
      case EnergyLevel.highEnergy:
        return _errorRed;
      case EnergyLevel.lowEnergy:
        return _textSecondary;
      case EnergyLevel.renewal:
        return _successGreen;
    }
  }
}