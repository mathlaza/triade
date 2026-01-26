import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/tutorial_animations.dart';

/// PÁGINA 5 - Weekly View
/// Explica a visualização semanal e o drag & drop vertical entre dias
class WeeklyViewPage extends StatefulWidget {
  const WeeklyViewPage({super.key});

  @override
  State<WeeklyViewPage> createState() => _WeeklyViewPageState();
}

class _WeeklyViewPageState extends State<WeeklyViewPage>
    with TickerProviderStateMixin {
  late AnimationController _dragController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  
  late Animation<double> _dragProgress;
  late Animation<double> _taskOpacity;
  late Animation<double> _draggedTaskY;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Controlador principal do drag (4.5 segundos por ciclo)
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();

    // Controlador do pulso do ícone de toque
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Controlador do glow
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    // Animação do progresso do drag (0 = início, 1 = fim)
    _dragProgress = TweenSequence<double>([
      // Fase 1: Esperando (tarefa parada)
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 0.15),
      // Fase 2: Começando a arrastar (lift)
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 0.1),
      // Fase 3: Arrastando para baixo
      TweenSequenceItem(tween: Tween(begin: 0.1, end: 0.9), weight: 0.35),
      // Fase 4: Soltando
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 0.1),
      // Fase 5: Esperando (tarefa no novo lugar)
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 0.15),
      // Fase 6: Reset (volta instantânea)
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 0.15),
    ]).animate(CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeInOut,
    ));

    // Opacidade da tarefa original (some quando arrastando)
    _taskOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 0.15),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.3), weight: 0.1),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.3), weight: 0.35),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.0), weight: 0.1),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 0.15),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 0.15),
    ]).animate(_dragController);

    // Posição Y da tarefa sendo arrastada
    _draggedTaskY = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.0), weight: 0.15),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 10.0), weight: 0.1),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: 95.0), weight: 0.35),
      TweenSequenceItem(tween: Tween(begin: 95.0, end: 105.0), weight: 0.1),
      TweenSequenceItem(tween: Tween(begin: 105.0, end: 105.0), weight: 0.15),
      TweenSequenceItem(tween: Tween(begin: 105.0, end: 0.0), weight: 0.15),
    ]).animate(CurvedAnimation(
      parent: _dragController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _dragController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  bool get _isDragging => _dragProgress.value > 0.05 && _dragProgress.value < 0.95;
  bool get _isOverTarget => _dragProgress.value > 0.5 && _dragProgress.value < 0.95;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Título
          const FadeSlideWidget(
            delay: Duration(milliseconds: 200),
            child: Text(
              'Planejamento Semanal',
              style: TextStyle(
                color: TutorialColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Descrição
          const FadeSlideWidget(
            delay: Duration(milliseconds: 300),
            child: Text(
              'Visualize toda a semana e reorganize arrastando tarefas entre os dias.',
              style: TextStyle(
                color: TutorialColors.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Mock da Weekly View (fiel à tela real)
          FadeSlideWidget(
            delay: const Duration(milliseconds: 400),
            child: _buildWeeklyViewMock(),
          ),
          const SizedBox(height: 14),

          // Instruções compactas
          FadeSlideWidget(
            delay: const Duration(milliseconds: 500),
            child: _buildInstructions(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildWeeklyViewMock() {
    return Container(
      decoration: BoxDecoration(
        color: TutorialColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TutorialColors.border),
      ),
      child: Column(
        children: [
          // Header com navegação de semanas
          _buildWeekHeader(),
          
          // Filtros
          _buildFilters(),
          
          // Lista de dias (vertical - como na tela real!)
          _buildDaysList(),
        ],
      ),
    );
  }

  Widget _buildWeekHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: TutorialColors.border.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Icon(Icons.chevron_left_rounded, color: TutorialColors.textSecondary, size: 22),
          Column(
            children: [
              const Text(
                'S4 de 2026',
                style: TextStyle(
                  color: TutorialColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: TutorialColors.gold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Atual',
                      style: TextStyle(
                        color: TutorialColors.gold,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '26/01 - 01/02',
                    style: TextStyle(
                      color: TutorialColors.textSecondary.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.chevron_right_rounded, color: TutorialColors.textSecondary, size: 22),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('Todos', true),
          const SizedBox(width: 6),
          _buildFilterChip('Computador', false),
          const SizedBox(width: 6),
          _buildFilterChip('Casa', false),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? TutorialColors.gold.withValues(alpha: 0.15) : TutorialColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? TutorialColors.gold : TutorialColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? TutorialColors.gold : TutorialColors.textSecondary,
          fontSize: 10,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  Widget _buildDaysList() {
    return AnimatedBuilder(
      animation: Listenable.merge([_dragController, _pulseController, _glowController]),
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                children: [
                  // Dia 1 - Segunda (com a tarefa que será arrastada)
                  _buildDayCard(
                    day: 'Seg',
                    date: '26/01',
                    hours: '1.9h / 8.0h',
                    isToday: true,
                    tasks: [
                      _buildTaskInDay(
                        title: 'Reunião de equipe',
                        context: 'Reunião',
                        duration: '1.0h',
                        color: TutorialColors.highEnergy,
                        opacity: _taskOpacity.value,
                        showTouchIndicator: _dragProgress.value < 0.1,
                      ),
                      _buildTaskInDay(
                        title: 'Revisar emails',
                        context: 'Computador',
                        duration: '0.5h',
                        color: TutorialColors.lowEnergy,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Dia 2 - Terça (área de drop)
                  _buildDayCard(
                    day: 'Ter',
                    date: '27/01',
                    hours: '0.5h / 8.0h',
                    isDropTarget: _isOverTarget,
                    tasks: [
                      _buildTaskInDay(
                        title: 'Relatório mensal',
                        context: 'Computador',
                        duration: '0.5h',
                        color: TutorialColors.renewal,
                      ),
                    ],
                  ),
                ],
              ),
              
              // Tarefa flutuante sendo arrastada
              if (_isDragging)
                Positioned(
                  top: _draggedTaskY.value,
                  left: 0,
                  right: 0,
                  child: _buildDraggingTask(),
                ),
              
              // Tooltip flutuante com nome da tarefa
              if (_isDragging)
                Positioned(
                  top: _draggedTaskY.value - 30,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _glowAnimation,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: TutorialColors.gold.withValues(alpha: _glowAnimation.value * 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Text(
                            'Reunião de equipe',
                            style: TextStyle(
                              color: TutorialColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDayCard({
    required String day,
    required String date,
    required String hours,
    bool isToday = false,
    bool isDropTarget = false,
    required List<Widget> tasks,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDropTarget 
            ? TutorialColors.gold.withValues(alpha: 0.1)
            : isToday 
                ? TutorialColors.gold.withValues(alpha: 0.05)
                : TutorialColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDropTarget 
              ? TutorialColors.gold 
              : isToday 
                  ? TutorialColors.gold.withValues(alpha: 0.5)
                  : TutorialColors.border,
          width: isDropTarget ? 2 : 1,
        ),
        boxShadow: isDropTarget
            ? [
                BoxShadow(
                  color: TutorialColors.gold.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do dia
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isToday)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: TutorialColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    '$day, $date',
                    style: TextStyle(
                      color: isToday ? TutorialColors.gold : TutorialColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                hours,
                style: TextStyle(
                  color: TutorialColors.textSecondary.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
          if (isDropTarget) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: TutorialColors.gold,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
                color: TutorialColors.gold.withValues(alpha: 0.1),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: TutorialColors.gold,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Solte aqui para mover',
                    style: TextStyle(
                      color: TutorialColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          ...tasks,
        ],
      ),
    );
  }

  Widget _buildTaskInDay({
    required String title,
    required String context,
    required String duration,
    required Color color,
    double opacity = 1.0,
    bool showTouchIndicator = false,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: opacity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(color: color, width: 3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: TutorialColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          context,
                          style: TextStyle(
                            color: color,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  duration,
                  style: TextStyle(
                    color: TutorialColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          
          // Indicador de toque pulsante
          if (showTouchIndicator)
            Positioned(
              right: -5,
              top: -5,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: TutorialColors.gold,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: TutorialColors.gold.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.touch_app_rounded,
                        color: Colors.black,
                        size: 16,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDraggingTask() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: TutorialColors.highEnergy.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: TutorialColors.gold,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: TutorialColors.gold.withValues(alpha: _glowAnimation.value * 0.6),
                blurRadius: 15,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ícone de drag
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: TutorialColors.gold.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.drag_indicator_rounded,
                  color: TutorialColors.gold,
                  size: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Reunião de equipe',
                      style: TextStyle(
                        color: TutorialColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: TutorialColors.highEnergy.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Reunião',
                        style: TextStyle(
                          color: TutorialColors.highEnergy,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Indicador de movimento
              AnimatedBuilder(
                animation: _dragController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, math.sin(_dragController.value * math.pi * 8) * 2),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: TutorialColors.gold,
                      size: 18,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            TutorialColors.gold.withValues(alpha: 0.12),
            TutorialColors.gold.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: TutorialColors.gold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Ícones empilhados
          Column(
            children: [
              _buildInstructionIcon(Icons.touch_app_rounded, '1'),
              const SizedBox(height: 4),
              Container(width: 1, height: 12, color: TutorialColors.gold.withValues(alpha: 0.3)),
              const SizedBox(height: 4),
              _buildInstructionIcon(Icons.open_with_rounded, '2'),
              const SizedBox(height: 4),
              Container(width: 1, height: 12, color: TutorialColors.gold.withValues(alpha: 0.3)),
              const SizedBox(height: 4),
              _buildInstructionIcon(Icons.check_circle_outline_rounded, '3'),
            ],
          ),
          const SizedBox(width: 12),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInstructionText('Segure pressionado na tarefa'),
                const SizedBox(height: 10),
                _buildInstructionText('Arraste verticalmente para outro dia'),
                const SizedBox(height: 10),
                _buildInstructionText('Solte para confirmar a mudança'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionIcon(IconData icon, String number) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: TutorialColors.gold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(icon, color: TutorialColors.gold, size: 16),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: TutorialColors.gold,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: TutorialColors.textSecondary,
        fontSize: 11,
        height: 1.2,
      ),
    );
  }
}
