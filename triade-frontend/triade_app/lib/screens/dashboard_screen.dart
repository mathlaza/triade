import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/models/history_task.dart';
import 'package:triade_app/models/dashboard_stats.dart';
import 'package:triade_app/widgets/user_avatar_menu.dart';
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

  _HistoryData({
    required this.isLoading,
    required this.tasks,
    required this.hasMore,
    required this.searchTerm,
    required this.errorMessage,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _HistoryData &&
          runtimeType == other.runtimeType &&
          isLoading == other.isLoading &&
          tasks.length == other.tasks.length &&
          hasMore == other.hasMore &&
          searchTerm == other.searchTerm &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(isLoading, tasks.length, hasMore, searchTerm, errorMessage);
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
      _buildChartWithStats(stats),
      const SizedBox(height: 16),
      
      // 🔥 CARD DE INSIGHTS OCUPANDO LINHA INTEIRA
      _buildFullWidthInsightCard(stats),
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
          child: _buildPeriodButton(
            label: 'Semana',
            value: 'week',
            isSelected: _selectedPeriod == 'week',
            onTap: () {
              setState(() => _selectedPeriod = 'week');
              context.read<TaskProvider>().loadDashboardStats('week');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildPeriodButton(
            label: 'Mês',
            value: 'month',
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



Widget _buildChartWithStats(stats) {
  final distribution = stats.distribution;
  final dateFormat = DateFormat('dd/MM');
  
  if (stats.totalMinutesDone == 0) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF38383A)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline_rounded, size: 48, color: Colors.grey.shade600),
          const SizedBox(height: 12),
          Text(
            'Nenhuma tarefa concluída neste período',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF1C1C1E),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF38383A)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        // Header com título e stats
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats no canto esquerdo
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge de período
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD60A).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${dateFormat.format(stats.dateRange.start)} - ${dateFormat.format(stats.dateRange.end)}',
                    style: const TextStyle(
                      color: Color(0xFFFFD60A),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Horas concluídas
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFFD60A), Color(0xFFFFA500)],
                  ).createShader(bounds),
                  child: Text(
                    '${stats.totalHoursDone.toStringAsFixed(1)}h',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                const Text(
                  'concluídas',
                  style: TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // Título
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Distribuição',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const Text(
                  'da Tríade',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFD60A),
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Gráfico de pizza
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 40,
              sections: [
                PieChartSectionData(
                  value: distribution.highEnergy,
                  title: '${distribution.highEnergy.toStringAsFixed(0)}%',
                  color: AppConstants.highEnergyColor,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                  ),
                ),
                PieChartSectionData(
                  value: distribution.renewal,
                  title: '${distribution.renewal.toStringAsFixed(0)}%',
                  color: AppConstants.renewalColor,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                  ),
                ),
                PieChartSectionData(
                  value: distribution.lowEnergy,
                  title: '${distribution.lowEnergy.toStringAsFixed(0)}%',
                  color: AppConstants.lowEnergyColor,
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black38, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    ),
  );
}


Widget _buildFullWidthInsightCard(stats) {
  final insight = stats.insight;
  final color = _parseHexColor(insight.colorHex);

  IconData getInsightIcon(String type) {
    switch (type) {
      case 'BURNOUT':
        return Icons.local_fire_department_rounded;
      case 'LAZY':
        return Icons.bedtime_rounded;
      case 'BALANCED':
        return Icons.check_circle_rounded;
      default:
        return Icons.psychology_rounded;
    }
  }

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          color.withValues(alpha: 0.15),
          color.withValues(alpha: 0.05),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: color.withValues(alpha: 0.4),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: color.withValues(alpha: 0.15),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header com ícone e título
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Icon(getInsightIcon(insight.type), color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INSIGHT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8E8E93),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    insight.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Mensagem
        Text(
          insight.message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}


Widget _buildPeriodButton({
  required String label,
  required String value,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: isSelected
            ? const LinearGradient(
                colors: [Color(0xFFFFD60A), Color(0xFFFFA500)],
              )
            : null,
        color: isSelected ? null : const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFFFFD60A) : const Color(0xFF38383A),
          width: 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFFFD60A).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? const Color(0xFF000000) : const Color(0xFFE5E5E5),
            fontWeight: FontWeight.w700,
            fontSize: 14,
            letterSpacing: -0.2,
          ),
        ),
      ),
    ),
  );
}

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('🧠 Alta', AppConstants.highEnergyColor),
        _buildLegendItem('🔋 Renovação', AppConstants.renewalColor),
        _buildLegendItem('🌙 Baixa', AppConstants.lowEnergyColor),
      ],
    );
  }

Widget _buildLegendItem(String label, Color color) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    ],
  );
}

  Color _parseHexColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
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
        _buildSearchBar(),
        
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
          if (showHeader) _buildDateHeader(task.completedAt, isFirst: index == 0),
          _buildHistoryTaskTile(task),
        ],
      );
    },
  );
}

  Widget _buildSearchBar() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), // 🔥 Sem bottom extra
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFF1A1A2E),
          Color(0xFF16213E),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: TextField(
      controller: _searchController,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'Buscar tarefa antiga...',
        hintStyle: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xFFFFD700), size: 20),
        suffixIcon: _searchController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, size: 20, color: Color(0xFF9CA3AF)),
                onPressed: () {
                  _searchController.clear();
                  context.read<TaskProvider>().clearHistorySearch();
                  context.read<TaskProvider>().loadHistory();
                },
              )
            : null,
        filled: true,
        fillColor: const Color(0xFF0F1419).withValues(alpha: 0.8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF374151), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF374151), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      onChanged: _onSearchChanged,
    ),
  );
}

  Widget _buildDateHeader(DateTime date, {bool isFirst = false}) { // 🔥 Parâmetro isFirst
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final taskDate = DateTime(date.year, date.month, date.day);

  String dayLabel;
  String dateLabel = DateFormat('dd/MM/yyyy', 'pt_BR').format(date);
  
  if (taskDate.isAtSameMomentAs(today)) {
    dayLabel = 'Hoje';
  } else if (taskDate.isAtSameMomentAs(yesterday)) {
    dayLabel = 'Ontem';
  } else if (taskDate.isAfter(today.subtract(const Duration(days: 7))) && taskDate.isBefore(today)) {
    final weekday = DateFormat('EEEE', 'pt_BR').format(date);
    dayLabel = weekday[0].toUpperCase() + weekday.substring(1);
  } else if (taskDate.year == today.year) {
    dayLabel = DateFormat('d \'de\' MMMM', 'pt_BR').format(date);
    dateLabel = '';
  } else {
    dayLabel = DateFormat('MMMM yyyy', 'pt_BR').format(date);
    dateLabel = '';
  }

  return Container(
    margin: EdgeInsets.only(
      top: isFirst ? 8 : 14, // 🔥 8px apenas no primeiro, 14px nos demais
      bottom: 5,
      left: 16,
      right: 16,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 🔥 20% menor (era 8)
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [
          Color(0xFFFFD700),
          Color(0xFFFFA500),
        ],
      ),
      borderRadius: BorderRadius.circular(7),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(
      children: [
        const Icon(
          Icons.calendar_today,
          size: 14,
          color: Color(0xFF1A1A2E),
        ),
        const SizedBox(width: 8),
        Text(
          dayLabel,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A2E),
            letterSpacing: 0.4,
          ),
        ),
        if (dateLabel.isNotEmpty) ...[
          const SizedBox(width: 6),
          Text(
            '• $dateLabel',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16213E),
            ),
          ),
        ],
      ],
    ),
  );
}

  Widget _buildHistoryTaskTile(HistoryTask task) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2), // 🔥 Menor espaçamento
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x26FFFFFF),
          Color(0x14FFFFFF),
        ],
      ),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: const Color(0x33FFFFFF),
        width: 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x4D000000),
          blurRadius: 8,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTaskDetailModal(task),
        borderRadius: BorderRadius.circular(10),
        splashColor: const Color(0x33FFD700),
        highlightColor: const Color(0x1AFFD700),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 🔥 2/3 do tamanho (era 10)
          child: Row(
            children: [
              // Indicador de categoria
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: task.energyLevel.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: task.energyLevel.color.withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13, // 🔥 Menor
                              color: Colors.white,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        _buildPerformanceIndicator(task),
                      ],
                    ),
                    const SizedBox(height: 2), // 🔥 Menor
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 11, // 🔥 Menor
                          color: Color(0xFFFFD700),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.formattedDuration,
                          style: const TextStyle(
                            fontSize: 11, // 🔥 Menor
                            color: Color(0xFFE5E7EB),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (task.contextTag != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFD700),
                                  Color(0xFFFFA500),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              task.contextTag!,
                              style: const TextStyle(
                                fontSize: 9, // 🔥 Menor
                                color: Color(0xFF1A1A2E),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFFFFD700),
                size: 18, // 🔥 Menor
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildPerformanceIndicator(HistoryTask task) {
    final indicator = task.performanceIndicator;
    
    if (indicator == PerformanceIndicator.onTime) {
      return const SizedBox.shrink(); // Não mostra nada se estiver no prazo
    }

    final isAnticipated = indicator == PerformanceIndicator.anticipated;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAnticipated ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isAnticipated ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAnticipated ? Icons.flash_on : Icons.schedule,
            size: 12,
            color: isAnticipated ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 2),
          Text(
            isAnticipated ? 'Antecipada' : 'Atrasada',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isAnticipated ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetailModal(HistoryTask task) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de arrasto
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Header compacto
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: task.energyLevel.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: task.energyLevel.color.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            
            // Descrição (se existir)
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0x33FFFFFF),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE5E7EB),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            
            // Grid compacto 2 colunas
            Row(
              children: [
                Expanded(
                  child: _buildCompactDetail(
                    Icons.category_outlined,
                    task.energyLevel.label,
                    task.energyLevel.color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCompactDetail(
                    Icons.timer_outlined,
                    task.formattedDuration,
                    const Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildCompactDetail(
                    Icons.check_circle_outline,
                    DateFormat('dd/MM HH:mm', 'pt_BR').format(task.completedAt),
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCompactDetail(
                    Icons.event_outlined,
                    DateFormat('dd/MM/yyyy', 'pt_BR').format(task.dateScheduled),
                    const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            if (task.contextTag != null || task.roleTag != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (task.contextTag != null)
                    Expanded(
                      child: _buildCompactDetail(
                        Icons.label_outline,
                        task.contextTag!,
                        const Color(0xFFFF9800),
                      ),
                    ),
                  if (task.contextTag != null && task.roleTag != null)
                    const SizedBox(width: 10),
                  if (task.roleTag != null)
                    Expanded(
                      child: _buildCompactDetail(
                        Icons.person_outline,
                        task.roleTag!,
                        const Color(0xFF9C27B0),
                      ),
                    ),
                ],
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Botão compacto
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildCompactDetail(IconData icon, String value, Color accentColor) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
      ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: accentColor.withValues(alpha: 0.25),
        width: 1,
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: accentColor),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    ),
  );
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}
}