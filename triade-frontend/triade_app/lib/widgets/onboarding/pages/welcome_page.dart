import 'package:flutter/material.dart';
import '../widgets/tutorial_animations.dart';

/// PÁGINA 1 - Boas-vindas
/// Introduz o conceito do app e a Tríade de Energia
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo animado
          FadeSlideWidget(
            delay: const Duration(milliseconds: 200),
            child: ShimmerEffect(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: TutorialColors.gold.withValues(alpha: 0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/triade_foreground.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: TutorialColors.gold,
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 50,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Título de boas-vindas
          const FadeSlideWidget(
            delay: Duration(milliseconds: 400),
            child: Text(
              'Bem-vindo ao\nTríade da Energia',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TutorialColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Descrição principal
          const FadeSlideWidget(
            delay: Duration(milliseconds: 600),
            child: Text(
              'Organize suas tarefas de forma inteligente, baseada na sua energia disponível.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: TutorialColors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Cards dos três níveis de energia
          FadeSlideWidget(
            delay: const Duration(milliseconds: 800),
            child: _buildEnergyLevelsPreview(),
          ),
          const SizedBox(height: 20),

          // Call to action
          const FadeSlideWidget(
            delay: Duration(milliseconds: 1000),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Vamos começar!',
                  style: TextStyle(
                    color: TutorialColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                AnimatedArrow(
                  direction: AxisDirection.right,
                  color: TutorialColors.gold,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyLevelsPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TutorialColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TutorialColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'As três categorias de energia:',
            style: TextStyle(
              color: TutorialColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _buildEnergyRow(
            emoji: '🧠',
            title: 'Alta Energia',
            description: 'Foco total e concentração máxima',
            color: TutorialColors.highEnergy,
            delay: 900,
          ),
          const SizedBox(height: 10),
          _buildEnergyRow(
            emoji: '🔋',
            title: 'Renovação',
            description: 'Atividades que recarregam',
            color: TutorialColors.renewal,
            delay: 1000,
          ),
          const SizedBox(height: 10),
          _buildEnergyRow(
            emoji: '🌙',
            title: 'Baixa Energia',
            description: 'Tarefas simples e automáticas',
            color: TutorialColors.lowEnergy,
            delay: 1100,
          ),
        ],
      ),
    );
  }

  Widget _buildEnergyRow({
    required String emoji,
    required String title,
    required String description,
    required Color color,
    required int delay,
  }) {
    return FadeSlideWidget(
      delay: Duration(milliseconds: delay),
      slideOffset: const Offset(20, 0),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20),
              ),
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
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    color: TutorialColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
