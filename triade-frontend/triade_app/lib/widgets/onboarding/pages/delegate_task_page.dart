import 'package:flutter/material.dart';
import '../widgets/tutorial_animations.dart';
import '../widgets/mock_widgets.dart';

/// PÁGINA 3 - Delegando Tarefas
/// Explica como delegar tarefas e onde encontrá-las
class DelegateTaskPage extends StatefulWidget {
  const DelegateTaskPage({super.key});

  @override
  State<DelegateTaskPage> createState() => _DelegateTaskPageState();
}

class _DelegateTaskPageState extends State<DelegateTaskPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.0), weight: 1),
    ]).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

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
              'Delegando Tarefas',
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
              'Delegue tarefas para outras pessoas e acompanhe o progresso sem ocupar sua capacidade diária.',
              style: TextStyle(
                color: TutorialColors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Como delegar
          FadeSlideWidget(
            delay: const Duration(milliseconds: 400),
            child: _buildDelegateSection(),
          ),
          const SizedBox(height: 24),

          // Card de tarefa delegada
          FadeSlideWidget(
            delay: const Duration(milliseconds: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tarefa delegada aparece assim:',
                  style: TextStyle(
                    color: TutorialColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: const MockTaskCard(
                        title: 'Revisar relatório mensal',
                        durationMinutes: 45,
                        energyColor: TutorialColors.highEnergy,
                        isDelegated: true,
                        delegatedTo: 'João',
                        isHighlighted: true,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Onde encontrar
          FadeSlideWidget(
            delay: const Duration(milliseconds: 600),
            child: _buildWhereToFind(),
          ),
          const SizedBox(height: 24),

          // Benefício
          FadeSlideWidget(
            delay: const Duration(milliseconds: 700),
            child: _buildBenefitCard(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDelegateSection() {
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
                Icons.person_add_alt_1_rounded,
                color: TutorialColors.gold,
                size: 22,
              ),
              SizedBox(width: 10),
              Text(
                'Como delegar:',
                style: TextStyle(
                  color: TutorialColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStep(
            number: '1',
            text: 'Ao criar ou editar uma tarefa, preencha o campo "Delegado para"',
          ),
          const SizedBox(height: 10),
          _buildStep(
            number: '2',
            text: 'Defina uma data de follow-up para acompanhamento',
          ),
          const SizedBox(height: 10),
          _buildStep(
            number: '3',
            text: 'A tarefa ficará marcada como delegada',
          ),
        ],
      ),
    );
  }

  Widget _buildStep({required String number, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: TutorialColors.gold.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: TutorialColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: TutorialColors.textSecondary,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhereToFind() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TutorialColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TutorialColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: TutorialColors.gold,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Onde encontrar:',
                style: TextStyle(
                  color: TutorialColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          
          // Miniatura do menu suspenso real (centralizado)
          Center(
            child: Container(
              width: 180, // Largura mais fina como o original
              decoration: BoxDecoration(
                color: TutorialColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TutorialColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header do menu com avatar e nome
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: TutorialColors.border.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(1.5),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [TutorialColors.gold, TutorialColors.goldDark],
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundImage: AssetImage('assets/me.jpeg'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Matheus Lazaro',
                              style: TextStyle(
                                color: TutorialColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '@matheus',
                              style: TextStyle(
                                color: TutorialColors.textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Itens do menu
                  _buildMiniMenuItem(Icons.person_outline_rounded, 'Ver Perfil', false),
                  _buildMiniMenuItem(Icons.edit_outlined, 'Editar Perfil', false),
                  _buildMiniMenuItem(Icons.people_alt_rounded, 'Tarefas Delegadas', true), // Destacado!
                  _buildMiniMenuItem(Icons.lock_outline_rounded, 'Alterar Senha', false),
                  _buildMiniMenuItem(Icons.school_rounded, 'Tutorial', false),
                  
                  // Sair (vermelho)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          color: Colors.red.shade400,
                          size: 12,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sair',
                          style: TextStyle(
                            color: Colors.red.shade400,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Acesse pelo menu do seu avatar no canto superior direito.',
            style: TextStyle(
              color: TutorialColors.textSecondary,
              fontSize: 11,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMenuItem(IconData icon, String label, bool isHighlighted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: isHighlighted
          ? BoxDecoration(
              color: TutorialColors.gold.withValues(alpha: 0.1),
              border: const Border(
                left: BorderSide(color: TutorialColors.gold, width: 2),
              ),
            )
          : null,
      child: Row(
        children: [
          Icon(
            icon,
            color: isHighlighted ? TutorialColors.gold : TutorialColors.textSecondary,
            size: 12,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: isHighlighted ? TutorialColors.gold : TutorialColors.textSecondary,
              fontSize: 10,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TutorialColors.renewal.withValues(alpha: 0.15),
            TutorialColors.renewal.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TutorialColors.renewal.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TutorialColors.renewal.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.battery_full_rounded,
              color: TutorialColors.renewal,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Economize sua energia!',
                  style: TextStyle(
                    color: TutorialColors.renewal,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tarefas delegadas não contam como horas gastas na sua capacidade diária.',
                  style: TextStyle(
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
}
