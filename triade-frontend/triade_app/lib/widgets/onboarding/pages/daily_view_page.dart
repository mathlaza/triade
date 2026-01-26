import 'package:flutter/material.dart';
import '../widgets/tutorial_animations.dart';
import '../widgets/mock_widgets.dart';

/// PÁGINA 4 - Daily View
/// Mostra a visualização diária e como funciona
class DailyViewPage extends StatelessWidget {
  const DailyViewPage({super.key});

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
              'Visualização Diária',
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
              'Sua central de comando para o dia. Veja todas as tarefas organizadas por nível de energia.',
              style: TextStyle(
                color: TutorialColors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mock do Date Selector
          FadeSlideWidget(
            delay: const Duration(milliseconds: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureLabel('Navegue entre os dias:'),
                const SizedBox(height: 8),
                const MockDateSelector(
                  displayDate: 'Sábado, 25 de Janeiro',
                  isToday: true,
                  isHighlighted: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Mock da Progress Bar
          FadeSlideWidget(
            delay: const Duration(milliseconds: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureLabel('Acompanhe sua capacidade:'),
                const SizedBox(height: 8),
                const MockProgressBar(
                  usedHours: 4.5,
                  availableHours: 8.0,
                  highEnergyHours: 2.0,
                  renewalHours: 1.5,
                  lowEnergyHours: 1.0,
                  isHighlighted: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Mock das seções de energia
          FadeSlideWidget(
            delay: const Duration(milliseconds: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFeatureLabel('Tarefas por energia:'),
                const SizedBox(height: 8),
                _buildMiniEnergySections(),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dicas de interação
          FadeSlideWidget(
            delay: const Duration(milliseconds: 700),
            child: _buildInteractionTips(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeatureLabel(String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: TutorialColors.gold,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            color: TutorialColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniEnergySections() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TutorialColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TutorialColors.border),
      ),
      child: Column(
        children: [
          _buildMiniSection(
            emoji: '🧠',
            title: 'Alta Energia',
            color: TutorialColors.highEnergy,
            taskCount: 2,
          ),
          const SizedBox(height: 12),
          _buildMiniSection(
            emoji: '🔋',
            title: 'Renovação',
            color: TutorialColors.renewal,
            taskCount: 1,
          ),
          const SizedBox(height: 12),
          _buildMiniSection(
            emoji: '🌙',
            title: 'Baixa Energia',
            color: TutorialColors.lowEnergy,
            taskCount: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniSection({
    required String emoji,
    required String title,
    required Color color,
    required int taskCount,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 16)),
          ),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$taskCount tarefa${taskCount > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: TutorialColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$taskCount',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInteractionTips() {
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
                Icons.tips_and_updates_rounded,
                color: TutorialColors.gold,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Interações rápidas:',
                style: TextStyle(
                  color: TutorialColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipRow(
            icon: Icons.check_circle_outline_rounded,
            text: 'Toque no círculo para marcar como concluída',
          ),
          const SizedBox(height: 10),
          _buildTipRow(
            icon: Icons.swipe_left_rounded,
            text: 'Deslize para a esquerda para excluir',
          ),
          const SizedBox(height: 10),
          _buildTipRow(
            icon: Icons.touch_app_rounded,
            text: 'Segure pressionado para editar',
          ),
          const SizedBox(height: 10),
          _buildTipRow(
            icon: Icons.tune_rounded,
            text: 'Toque nas horas para ajustar capacidade',
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(
          icon,
          color: TutorialColors.gold.withValues(alpha: 0.7),
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: TutorialColors.textSecondary,
              fontSize: 13,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}
