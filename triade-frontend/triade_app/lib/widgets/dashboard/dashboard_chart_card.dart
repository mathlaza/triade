import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:triade_app/config/constants.dart';
import 'package:triade_app/models/dashboard_stats.dart';
import 'package:triade_app/widgets/dashboard/chart_legend.dart';

/// Card de gráfico de pizza com estatísticas da Tríade
class DashboardChartCard extends StatelessWidget {
  final DashboardStats stats;

  const DashboardChartCard({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    final distribution = stats.distribution;
    final dateFormat = DateFormat('dd/MM');

    if (stats.totalMinutesDone == 0) {
      return _buildEmptyState();
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
          _buildHeader(dateFormat),
          const SizedBox(height: 16),
          _buildPieChart(distribution),
          const SizedBox(height: 16),
          const ChartLegend(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildHeader(DateFormat dateFormat) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
        const Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Distribuição',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            Text(
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
    );
  }

  Widget _buildPieChart(EnergyDistribution distribution) {
    return SizedBox(
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
    );
  }
}
