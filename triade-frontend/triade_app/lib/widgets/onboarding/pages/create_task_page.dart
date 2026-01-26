import 'package:flutter/material.dart';
import '../widgets/tutorial_animations.dart';
import '../widgets/mock_widgets.dart';

/// PÁGINA 2 - Criando e Editando Tarefas
/// Mostra como criar uma nova tarefa e os campos disponíveis
class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key});

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    _startStepAnimation();
  }

  void _startStepAnimation() async {
    while (mounted) {
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        setState(() {
          _currentStep = (_currentStep + 1) % _totalSteps;
        });
      }
    }
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
              'Criando Tarefas',
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
              'Toque no botão + para criar uma nova tarefa. Segure uma tarefa existente para editar.',
              style: TextStyle(
                color: TutorialColors.textSecondary,
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mock do FAB com destaque
          const FadeSlideWidget(
            delay: Duration(milliseconds: 400),
            child: Center(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedArrow(
                        direction: AxisDirection.right,
                        color: TutorialColors.gold,
                      ),
                      SizedBox(width: 16),
                      MockFab(showPulse: true),
                      SizedBox(width: 16),
                      AnimatedArrow(
                        direction: AxisDirection.left,
                        color: TutorialColors.gold,
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Toque para criar',
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
          const SizedBox(height: 32),

          // Form mock com highlights animados
          FadeSlideWidget(
            delay: const Duration(milliseconds: 500),
            child: _buildFormMock(),
          ),
          const SizedBox(height: 24),

          // Dica de edição
          FadeSlideWidget(
            delay: const Duration(milliseconds: 700),
            child: _buildEditTip(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFormMock() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TutorialColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: TutorialColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Campos da tarefa:',
            style: TextStyle(
              color: TutorialColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),

          // Campo: Título
          _buildFormField(
            icon: Icons.title_rounded,
            label: 'Título',
            hint: 'Nome da tarefa',
            isHighlighted: _currentStep == 0,
            isRequired: true,
          ),
          const SizedBox(height: 12),

          // Campo: Descrição
          _buildFormField(
            icon: Icons.notes_rounded,
            label: 'Descrição',
            hint: 'Detalhes opcionais',
            isHighlighted: _currentStep == 1,
          ),
          const SizedBox(height: 12),

          // Campo: Duração
          _buildFormField(
            icon: Icons.timer_outlined,
            label: 'Duração',
            hint: '30 minutos',
            isHighlighted: _currentStep == 2,
            isRequired: true,
          ),
          const SizedBox(height: 12),

          // Campo: Data/Horário
          _buildFormField(
            icon: Icons.event_rounded,
            label: 'Data e Horário',
            hint: 'Quando realizar',
            isHighlighted: _currentStep == 3,
          ),
          const SizedBox(height: 16),

          // Seletor de energia
          const Text(
            'Nível de Energia:',
            style: TextStyle(
              color: TutorialColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildEnergyChip('🧠', 'Alta', TutorialColors.highEnergy, true),
              const SizedBox(width: 8),
              _buildEnergyChip('🔋', 'Renovação', TutorialColors.renewal, false),
              const SizedBox(width: 8),
              _buildEnergyChip('🌙', 'Baixa', TutorialColors.lowEnergy, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required IconData icon,
    required String label,
    required String hint,
    bool isHighlighted = false,
    bool isRequired = false,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: TutorialColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? TutorialColors.gold : TutorialColors.border,
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: TutorialColors.gold.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isHighlighted ? TutorialColors.gold : TutorialColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isHighlighted
                            ? TutorialColors.gold
                            : TutorialColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isRequired)
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: TutorialColors.highEnergy,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  style: const TextStyle(
                    color: TutorialColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (isHighlighted)
            const AnimatedArrow(
              direction: AxisDirection.left,
              color: TutorialColors.gold,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _buildEnergyChip(String emoji, String label, Color color, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : TutorialColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : TutorialColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : TutorialColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TutorialColors.gold.withValues(alpha: 0.1),
            TutorialColors.gold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TutorialColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TutorialColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.touch_app_rounded,
              color: TutorialColors.gold,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dica: Editar tarefa',
                  style: TextStyle(
                    color: TutorialColors.gold,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Segure pressionado em qualquer tarefa para abrir a tela de edição.',
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
