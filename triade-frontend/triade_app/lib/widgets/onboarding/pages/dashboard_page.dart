import 'package:flutter/material.dart';
import '../widgets/tutorial_animations.dart';
import '../widgets/mock_widgets.dart';

/// PÁGINA 6 - Dashboard
/// Apresenta os gráficos, insights e histórico
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // Título
          const FadeSlideWidget(
            delay: Duration(milliseconds: 200),
            child: Text(
              'Dashboard',
              style: TextStyle(
                color: TutorialColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Descrição
          const FadeSlideWidget(
            delay: Duration(milliseconds: 300),
            child: Text(
              'Acompanhe sua produtividade com gráficos, insights e o histórico completo de tarefas concluídas.',
              style: TextStyle(
                color: TutorialColors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Tab bar mock
          FadeSlideWidget(
            delay: const Duration(milliseconds: 400),
            child: _buildTabBarMock(),
          ),
          const SizedBox(height: 24),

          // Gráficos
          FadeSlideWidget(
            delay: const Duration(milliseconds: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('📊 Distribuição de Energia'),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(
                      child: PulsingHighlight(
                        showGlow: true,
                        glowRadius: 12,
                        child: MockDashboardChart(
                          title: 'Esta Semana',
                          highEnergyPercent: 0.45,
                          renewalPercent: 0.30,
                          lowEnergyPercent: 0.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Insights
          FadeSlideWidget(
            delay: const Duration(milliseconds: 600),
            child: _buildInsightsSection(),
          ),
          const SizedBox(height: 24),

          // Histórico
          FadeSlideWidget(
            delay: const Duration(milliseconds: 700),
            child: _buildHistorySection(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTabBarMock() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TutorialColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: TutorialColors.gold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.insights_rounded,
                    color: TutorialColors.gold,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Visão Geral',
                    style: TextStyle(
                      color: TutorialColors.gold,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_rounded,
                    color: TutorialColors.textSecondary,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Histórico',
                    style: TextStyle(
                      color: TutorialColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: TutorialColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TutorialColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TutorialColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: TutorialColors.gold,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Insights Personalizados',
                style: TextStyle(
                  color: TutorialColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightCard(
            icon: Icons.trending_up_rounded,
            color: TutorialColors.renewal,
            title: 'Ótimo equilíbrio!',
            description: 'Você está distribuindo bem suas energias ao longo da semana.',
          ),
          const SizedBox(height: 12),
          _buildInsightCard(
            icon: Icons.schedule_rounded,
            color: TutorialColors.highEnergy,
            title: 'Pico de produtividade',
            description: 'Suas tarefas de alta energia são mais concluídas pela manhã.',
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: TutorialColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TutorialColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TutorialColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.history_rounded,
                color: TutorialColors.textSecondary,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Histórico de Tarefas',
                style: TextStyle(
                  color: TutorialColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Acesse todas as suas tarefas concluídas na aba Histórico.',
            style: TextStyle(
              color: TutorialColors.textSecondary,
              fontSize: 13,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // Search mock
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: TutorialColors.card,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.search_rounded,
                  color: TutorialColors.textSecondary,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  'Buscar no histórico...',
                  style: TextStyle(
                    color: TutorialColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Sample history items
          _buildHistoryItem(
            title: 'Reunião de planejamento',
            date: '24 Jan 2026',
            color: TutorialColors.highEnergy,
          ),
          const SizedBox(height: 8),
          _buildHistoryItem(
            title: 'Caminhada no parque',
            date: '23 Jan 2026',
            color: TutorialColors.renewal,
          ),
          const SizedBox(height: 8),
          _buildHistoryItem(
            title: 'Responder emails',
            date: '23 Jan 2026',
            color: TutorialColors.lowEnergy,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String date,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 36,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: TutorialColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  color: TutorialColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.check_circle_rounded,
          color: TutorialColors.renewal.withValues(alpha: 0.7),
          size: 18,
        ),
      ],
    );
  }
}
