import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:triade_app/providers/task_provider.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/models/history_task.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
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

  void _loadDashboardData() {
    final provider = context.read<TaskProvider>();
    provider.loadDashboardStats(_selectedPeriod);
    provider.loadHistory();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      // Carregar mais quando chegar a 80% do scroll
      context.read<TaskProvider>().loadHistory(loadMore: true);
    }
  }

  void _onSearchChanged(String value) {
    // Debounce: espera 500ms após o usuário parar de digitar
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      context.read<TaskProvider>().loadHistory(searchTerm: value.isEmpty ? null : value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // AppBar customizado
          Container(
            color: AppConstants.primaryColor,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              bottom: 8,
              left: 16,
              right: 16,
            ),
            child: const Text(
              'Dashboard',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // TabBar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppConstants.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppConstants.primaryColor,
              tabs: const [
                Tab(text: 'Visão Geral', icon: Icon(Icons.pie_chart)),
                Tab(text: 'Histórico', icon: Icon(Icons.history)),
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

  // ==================== ABA 1: VISÃO GERAL ====================
  
  Widget _buildOverviewTab() {
    return Consumer<TaskProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading && provider.dashboardStats == null) {
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
                  onPressed: _loadDashboardData,
                  child: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        final stats = provider.dashboardStats;
        if (stats == null) {
          return const Center(child: Text('Sem dados disponíveis'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Seletor de Período
              _buildPeriodSelector(provider),
              const SizedBox(height: 24),

              // Card de Resumo
              _buildSummaryCard(stats),
              const SizedBox(height: 24),

              // Gráfico de Pizza
              _buildPieChart(stats),
              const SizedBox(height: 24),

              // Card de Insights
              _buildInsightCard(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodSelector(TaskProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildPeriodButton(
            label: 'Semana',
            value: 'week',
            isSelected: _selectedPeriod == 'week',
            onTap: () {
              setState(() => _selectedPeriod = 'week');
              provider.loadDashboardStats('week');
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPeriodButton(
            label: 'Mês',
            value: 'month',
            isSelected: _selectedPeriod == 'month',
            onTap: () {
              setState(() => _selectedPeriod = 'month');
              provider.loadDashboardStats('month');
            },
          ),
        ),
      ],
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
          color: isSelected ? AppConstants.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(stats) {
  final dateFormat = DateFormat('dd/MM');
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [
          AppConstants.primaryColor,
          AppConstants.primaryColor.withValues(alpha: 0.7),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: AppConstants.primaryColor.withValues(alpha: 0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Text(
          '${dateFormat.format(stats.dateRange.start)} - ${dateFormat.format(stats.dateRange.end)}',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${stats.totalHoursDone.toStringAsFixed(1)}h',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'Horas Concluídas',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildPieChart(stats) {
    final distribution = stats.distribution;
    
    // Se não houver dados, mostrar mensagem
    if (stats.totalMinutesDone == 0) {
      return Container(
        height: 300,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Nenhuma tarefa concluída neste período',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Text(
          'Distribuição da Tríade',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 60,
              sections: [
                PieChartSectionData(
                  value: distribution.important,
                  title: '${distribution.important.toStringAsFixed(1)}%',
                  color: AppConstants.importantColor,
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: distribution.urgent,
                  title: '${distribution.urgent.toStringAsFixed(1)}%',
                  color: AppConstants.urgentColor,
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                PieChartSectionData(
                  value: distribution.circumstantial,
                  title: '${distribution.circumstantial.toStringAsFixed(1)}%',
                  color: AppConstants.circumstantialColor,
                  radius: 80,
                  titleStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(),
      ],
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Importante', AppConstants.importantColor),
        _buildLegendItem('Urgente', AppConstants.urgentColor),
        _buildLegendItem('Circunstancial', AppConstants.circumstantialColor),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInsightCard(stats) {
    final insight = stats.insight;
    final color = _parseHexColor(insight.colorHex);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: color, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.message,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
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
        
        // Lista de tarefas
        Expanded(
          child: Consumer<TaskProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.historyTasks.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFFD700), // Dourado
                  ),
                );
              }

              if (provider.errorMessage != null && provider.historyTasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Color(0xFFFF6B6B)),
                      const SizedBox(height: 16),
                      Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFFF6B6B)),
                      ),
                    ],
                  ),
                );
              }

              if (provider.historyTasks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey.shade700),
                      const SizedBox(height: 16),
                      Text(
                        provider.historySearchTerm != null
                            ? 'Nenhuma tarefa encontrada'
                            : 'Nenhuma tarefa concluída ainda',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              return _buildHistoryList(provider);
            },
          ),
        ),
      ],
    ),
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

  Widget _buildHistoryList(TaskProvider provider) {
  return ListView.builder(
    controller: _scrollController,
    padding: EdgeInsets.zero, // 🔥 ZERO padding no ListView
    itemCount: provider.historyTasks.length + (provider.hasMoreHistory ? 1 : 0),
    itemBuilder: (context, index) {
      // Loading indicator no final
      if (index == provider.historyTasks.length) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(
              color: Color(0xFFFFD700),
            ),
          ),
        );
      }

      final task = provider.historyTasks[index];
      
      final showHeader = index == 0 || !_isSameDay(
        task.completedAt,
        provider.historyTasks[index - 1].completedAt,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showHeader) _buildDateHeader(task.completedAt, isFirst: index == 0), // 🔥 Flag isFirst
          _buildHistoryTaskTile(task),
        ],
      );
    },
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
                  color: task.triadCategory.color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: task.triadCategory.color.withValues(alpha: 0.8),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, color: task.triadCategory.color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(Icons.category, 'Categoria', task.triadCategory.label),
            _buildDetailRow(Icons.timer, 'Duração', task.formattedDuration),
            _buildDetailRow(Icons.check_circle, 'Concluída em', DateFormat('dd/MM/yyyy HH:mm').format(task.completedAt)),
            _buildDetailRow(Icons.event, 'Agendada para', DateFormat('dd/MM/yyyy').format(task.dateScheduled)),
            if (task.contextTag != null)
              _buildDetailRow(Icons.label, 'Contexto', task.contextTag!),
            if (task.roleTag != null)
              _buildDetailRow(Icons.person, 'Papel', task.roleTag!),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
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