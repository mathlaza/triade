import 'package:flutter/material.dart';
import '../widgets/tutorial_animations.dart';

/// PÁGINA 7 - Conclusão
/// Página final agradecendo e convidando a começar
class CompletionPage extends StatelessWidget {
  const CompletionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone de sucesso animado
          FadeSlideWidget(
            delay: const Duration(milliseconds: 200),
            child: ShimmerEffect(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      TutorialColors.gold,
                      TutorialColors.goldDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: TutorialColors.gold.withValues(alpha: 0.4),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Colors.black,
                  size: 40,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Título
          const FadeSlideWidget(
            delay: Duration(milliseconds: 400),
            child: Text(
              'Você está pronto!',
              textAlign: TextAlign.center,
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
            delay: Duration(milliseconds: 500),
            child: Text(
              'Agora você conhece os recursos principais do Tríade da Energia. Comece a organizar suas tarefas de forma inteligente!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TutorialColors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Resumo dos recursos
          FadeSlideWidget(
            delay: const Duration(milliseconds: 600),
            child: _buildFeatureSummary(),
          ),
          const SizedBox(height: 20),

          // Dica simples
          FadeSlideWidget(
            delay: const Duration(milliseconds: 800),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: TutorialColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: TutorialColors.gold.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: TutorialColors.gold,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Reveja o tutorial a qualquer momento pelo menu do avatar.',
                      style: TextStyle(
                        color: TutorialColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeatureSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TutorialColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TutorialColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'O que você aprendeu:',
            style: TextStyle(
              color: TutorialColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildFeatureIcon(
                Icons.bolt_rounded,
                'Níveis de\nEnergia',
                TutorialColors.highEnergy,
              ),
              _buildFeatureIcon(
                Icons.add_task_rounded,
                'Criar\nTarefas',
                TutorialColors.gold,
              ),
              _buildFeatureIcon(
                Icons.people_rounded,
                'Delegar\nTarefas',
                TutorialColors.renewal,
              ),
              _buildFeatureIcon(
                Icons.calendar_view_week_rounded,
                'Planejar\nSemana',
                TutorialColors.lowEnergy,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureIcon(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TutorialColors.textSecondary,
            fontSize: 10,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}
