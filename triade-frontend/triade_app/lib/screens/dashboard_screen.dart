import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/models/history_task.dart';
import 'package:triade_app/models/dashboard_stats.dart';
import 'package:triade_app/widgets/user_avatar_menu.dart';
import 'package:triade_app/widgets/dashboard/dashboard_widgets.dart';
import 'package:triade_app/widgets/history/history_widgets.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';

// ✅ NOVO: Data class para Dashboard Stats - minimiza rebuilds
class _DashboardStatsData {
  final bool isLoading;
  final DashboardStats? stats;
  final String? errorMessage;

  _DashboardStatsData({
    required this.isLoading,
    required this.stats,
    required this.errorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _DashboardStatsData &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          stats?.totalMinutesDone == other.stats?.totalMinutesDone &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(isLoading, stats?.totalMinutesDone, errorMessage);
}

// ✅ NOVO: Data class para Histórico - minimiza rebuilds
class _HistoryData {
  final bool isLoading;
  final List<HistoryTask> tasks;
  final bool hasMore;
  final String? searchTerm;
  final String? errorMessage;
  final int _tasksHash; // ✅ Hash que detecta mudanças no conteúdo

  _HistoryData({
    required this.isLoading,
    required this.tasks,
    required this.hasMore,
    required this.searchTerm,
    required this.errorMessage,
  }) : _tasksHash = _computeTasksHash(tasks);
  
  /// ✅ Computa hash baseado nos IDs das tarefas
  static int _computeTasksHash(List<HistoryTask> tasks) {
    if (tasks.isEmpty) return 0;
    // Usa os primeiros 20 IDs para evitar recalcular em listas muito grandes
    final sample = tasks.take(20).map((t) => t.id).toList();
    return Object.hashAll(sample);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HistoryData &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          _tasksHash == other._tasksHash &&
          tasks.length == other.tasks.length &&
          hasMore == other.hasMore &&
          searchTerm == other.searchTerm &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(isLoading, _tasksHash, tasks.length, hasMore, searchTerm, errorMessage);
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // ✅ Mantém estado quando muda de aba

  late TabController _tabController;
  String _selectedPeriod = 'week';
  
  // Histórico
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scrollController.addListener(_onScroll);

    initializeDateFormatting('pt_BR', null);
    
    // Carregar dados iniciais
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void onBecameVisible() {
    _loadDashboardData();
  }

Future<void> _loadDashboardData() async {
  final provider = context.read<TaskProvider>();
  
  // ✅ Carrega stats PRIMEIRO e ESPERA terminar
  await provider.loadDashboardStats(_selectedPeriod);
  
  // ✅ SÓ DEPOIS carrega histórico
  await provider.loadHistory();
}

void _onScroll() {
  final provider = context.read<TaskProvider>();
  
  // ✅ CORREÇÃO: Passa o searchTerm atual para não resetar
  if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
    if (!provider.isLoading && provider.hasMoreHistory) {
      provider.loadHistory(
        loadMore: true,
        searchTerm: provider.historySearchTerm, // ✅ CRÍTICO: Preserva o termo de busca
      );
    }
  }
}

void _onSearchChanged(String value) {
  _debounceTimer?.cancel();
  _debounceTimer = Timer(const Duration(milliseconds: 500), () {
    // ✅ Passa null se vazio, ou o termo se preenchido
    final searchTerm = value.trim().isEmpty ? null : value.trim();
    context.read<TaskProvider>().loadHistory(
      loadMore: false, // ✅ NOVA BUSCA, não é loadMore
      searchTerm: searchTerm,
    );
  });
}

  @override
  Widget build(BuildContext context) {
    super.build(context); // ✅ Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Column(
        children: [
          // Header Premium (igual Daily View)
          _buildPremiumHeader(),
          
          // TabBar Dark
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F1419),
            ),
            child: TabBar(
              controller: _tabController,
              dividerColor: Colors.transparent,
              labelColor: const Color(0xFFFFD60A),
              unselectedLabelColor: const Color(0xFF8E8E93),
              indicatorColor: const Color(0xFFFFD60A),
              indicatorWeight: 2,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Visão Geral', icon: Icon(Icons.insights_rounded, size: 20)),
                Tab(text: 'Histórico', icon: Icon(Icons.history_rounded, size: 20)),
              ],
            ),
          ),

          // TabBarView
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildHistoryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
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
          // Espaço à esquerda para balancear
          const SizedBox(width: 42),
          // Centro com logo e título
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
                  'Dashboard',
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
          // Avatar
          const UserAvatarMenu(
            radius: 20,
            backgroundColor: Color(0xFF2C2C2E),
            showBorder: true,
            borderColor: Color(0xFFFFD60A),
          ),
        ],
      ),
    );
  }

  // ==================== ABA 1: VISÃO GERAL ====================
  
  Widget _buildOverviewTab() {
  return Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.fromARGB(255, 12, 12, 22),
          Color.fromARGB(255, 14, 21, 41),
          Color(0xFF0F1419),
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    ),
    child: Selector<TaskProvider, _DashboardStatsData>(
      selector: (_, provider) => _DashboardStatsData(
        isLoading: provider.isLoading,
        stats: provider.dashboardStats,
        errorMessage: provider.errorMessage,
      ),
      shouldRebuild: (prev, next) => prev != next,
      builder: (context, data, child) {
        if (data.isLoading && data.stats == null) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
          );
        }

        if (data.errorMessage != null && data.stats == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF6B6B)),
                const SizedBox(height: 16),
                Text(
                  data.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFFF6B6B)),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: _loadDashboardData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Tentar Novamente',
                      style: TextStyle(
                        color: Color(0xFF1A1A2E),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final stats = data.stats;
        if (stats == null) {
          return const Center(
            child: Text(
              'Sem dados disponíveis',
              style: TextStyle(color: Color(0xFF9CA3AF)),
            ),
          );
        }

return SingleChildScrollView(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildPeriodSelectorOptimized(),
      const SizedBox(height: 16),
      
      // 🔥 GRÁFICO COM STATS EMBUTIDOS
      DashboardChartCard(stats: stats),
      const SizedBox(height: 16),
      
      // 🔥 CARD DE INSIGHTS OCUPANDO LINHA INTEIRA
      DashboardInsightCard(insight: stats.insight),
    ],
  ),
);
      },
    ),
  );
}

  // ✅ Versão otimizada do period selector que não depende do provider
  Widget _buildPeriodSelectorOptimized() {
    return Row(
      children: [
        Expanded(
          child: PeriodSelectorButton(
            label: 'Semana',
            isSelected: _selectedPeriod == 'week',
            onTap: () {
              setState(() => _selectedPeriod = 'week');
              context.read<TaskProvider>().loadDashboardStats('week');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PeriodSelectorButton(
            label: 'Mês',
            isSelected: _selectedPeriod == 'month',
            onTap: () {
              setState(() => _selectedPeriod = 'month');
              context.read<TaskProvider>().loadDashboardStats('month');
            },
          ),
        ),
      ],
    );
  }

  // ==================== ABA 2: HISTÓRICO ====================
  
  Widget _buildHistoryTab() {
  return Container(
    // 🎨 Background escuro sofisticado com degradê sutil
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1A1A2E), // Azul escuro profundo
          Color(0xFF16213E), // Azul petróleo escuro
          Color(0xFF0F1419), // Quase preto
        ],
        stops: [0.0, 0.5, 1.0],
      ),
    ),
    child: Column(
      children: [
        // Barra de busca
        HistorySearchBar(
          controller: _searchController,
          onChanged: _onSearchChanged,
          onClear: () {
            _searchController.clear();
            context.read<TaskProvider>().clearHistorySearch();
            context.read<TaskProvider>().loadHistory();
          },
        ),
        
        // Lista de tarefas - ✅ OTIMIZADO com Selector
        Expanded(
          child: Selector<TaskProvider, _HistoryData>(
            selector: (_, provider) => _HistoryData(
              isLoading: provider.isLoading,
              tasks: provider.historyTasks,
              hasMore: provider.hasMoreHistory,
              searchTerm: provider.historySearchTerm,
              errorMessage: provider.errorMessage,
            ),
            shouldRebuild: (prev, next) => prev != next,
            builder: (context, data, child) {
              if (data.isLoading && data.tasks.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFD700), // Dourado
                  ),
                );
              }

              if (data.errorMessage != null && data.tasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF6B6B)),
                      const SizedBox(height: 16),
                      Text(
                        data.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFFF6B6B)),
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
                      Icon(Icons.history, size: 64, color: Colors.grey.shade700),
                      const SizedBox(height: 16),
                      Text(
                        data.searchTerm != null
                            ? 'Nenhuma tarefa encontrada'
                            : 'Nenhuma tarefa concluída ainda',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              return _buildHistoryListOptimized(data);
            },
          ),
        ),
      ],
    ),
  );
}

  // ✅ OTIMIZADO: Recebe data diretamente ao invés de provider
  Widget _buildHistoryListOptimized(_HistoryData data) {
  return ListView.builder(
    controller: _scrollController,
    padding: EdgeInsets.zero,
    itemCount: data.tasks.length + (data.hasMore ? 1 : 0),
    itemBuilder: (context, index) {
      // Loading indicator no final
      if (index == data.tasks.length) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(
              color: Color(0xFFFFD700),
            ),
          ),
        );
      }

      final task = data.tasks[index];
      
      final showHeader = index == 0 || !_isSameDay(
        task.completedAt,
        data.tasks[index - 1].completedAt,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) HistoryDateHeader(date: task.completedAt, isFirst: index == 0),
          HistoryTaskTile(task: task),
        ],
      );
    },
  );
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
}