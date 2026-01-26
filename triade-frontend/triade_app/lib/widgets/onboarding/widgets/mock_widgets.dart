import 'package:flutter/material.dart';
import 'tutorial_animations.dart';

// =====================================================================
// MOCK TASK CARD - Card de tarefa para demonstração
// =====================================================================
class MockTaskCard extends StatelessWidget {
  final String title;
  final String? description;
  final int durationMinutes;
  final Color energyColor;
  final String? contextTag;
  final bool isDone;
  final bool isDelegated;
  final String? delegatedTo;
  final bool isHighlighted;
  final bool showPulse;

  const MockTaskCard({
    super.key,
    required this.title,
    this.description,
    required this.durationMinutes,
    required this.energyColor,
    this.contextTag,
    this.isDone = false,
    this.isDelegated = false,
    this.delegatedTo,
    this.isHighlighted = false,
    this.showPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      decoration: BoxDecoration(
        color: isDone
            ? TutorialColors.renewal.withValues(alpha: 0.15)
            : TutorialColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: energyColor,
            width: 4,
          ),
        ),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: TutorialColors.gold.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? TutorialColors.renewal : Colors.transparent,
                    border: Border.all(
                      color: isDone ? TutorialColors.renewal : TutorialColors.textSecondary,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(
                          Icons.check_rounded,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Título
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDone
                          ? TutorialColors.textSecondary
                          : TutorialColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                // Duração
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: energyColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${durationMinutes}min',
                    style: TextStyle(
                      color: energyColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description!,
                style: const TextStyle(
                  color: TutorialColors.textSecondary,
                  fontSize: 13,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (isDelegated && delegatedTo != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    size: 14,
                    color: TutorialColors.gold,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Delegada para $delegatedTo',
                    style: const TextStyle(
                      color: TutorialColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
            if (contextTag != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TutorialColors.border,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  contextTag!,
                  style: const TextStyle(
                    color: TutorialColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (showPulse) {
      return PulsingHighlight(
        color: TutorialColors.gold,
        child: card,
      );
    }

    return card;
  }
}

// =====================================================================
// MOCK ENERGY SECTION - Seção de tarefas por energia
// =====================================================================
class MockEnergySection extends StatelessWidget {
  final String title;
  final String emoji;
  final Color color;
  final List<Widget> tasks;
  final bool isCollapsed;
  final bool isHighlighted;

  const MockEnergySection({
    super.key,
    required this.title,
    required this.emoji,
    required this.color,
    required this.tasks,
    this.isCollapsed = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: isHighlighted
            ? Border.all(color: TutorialColors.gold, width: 2)
            : null,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header da seção
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tasks
          if (!isCollapsed) ...tasks,
        ],
      ),
    );
  }
}

// =====================================================================
// MOCK PROGRESS BAR - Barra de progresso do dia
// =====================================================================
class MockProgressBar extends StatelessWidget {
  final double usedHours;
  final double availableHours;
  final double highEnergyHours;
  final double renewalHours;
  final double lowEnergyHours;
  final bool isHighlighted;

  const MockProgressBar({
    super.key,
    required this.usedHours,
    required this.availableHours,
    this.highEnergyHours = 0,
    this.renewalHours = 0,
    this.lowEnergyHours = 0,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    // progress é calculado para uso futuro em animações
    // ignore: unused_local_variable
    final progress = availableHours > 0 
        ? (usedHours / availableHours).clamp(0.0, 1.0) 
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TutorialColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(color: TutorialColors.gold, width: 2)
            : Border.all(color: TutorialColors.border.withValues(alpha: 0.5)),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: TutorialColors.gold.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Capacidade do Dia',
                style: TextStyle(
                  color: TutorialColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${usedHours.toStringAsFixed(1)}h',
                    style: const TextStyle(
                      color: TutorialColors.gold,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    ' / ${availableHours.toStringAsFixed(1)}h',
                    style: const TextStyle(
                      color: TutorialColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barra de progresso segmentada
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Stack(
                children: [
                  // Background
                  Container(color: TutorialColors.card),
                  // Segmentos de energia
                  Row(
                    children: [
                      if (highEnergyHours > 0)
                        Expanded(
                          flex: (highEnergyHours * 10).toInt(),
                          child: Container(color: TutorialColors.highEnergy),
                        ),
                      if (renewalHours > 0)
                        Expanded(
                          flex: (renewalHours * 10).toInt(),
                          child: Container(color: TutorialColors.renewal),
                        ),
                      if (lowEnergyHours > 0)
                        Expanded(
                          flex: (lowEnergyHours * 10).toInt(),
                          child: Container(color: TutorialColors.lowEnergy),
                        ),
                      Expanded(
                        flex: ((availableHours - usedHours).clamp(0, 24) * 10).toInt(),
                        child: Container(color: Colors.transparent),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Legenda
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('🧠', highEnergyHours, TutorialColors.highEnergy),
              _buildLegendItem('🔋', renewalHours, TutorialColors.renewal),
              _buildLegendItem('🌙', lowEnergyHours, TutorialColors.lowEnergy),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String emoji, double hours, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          emoji,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 2),
        Text(
          '${hours.toStringAsFixed(1)}h',
          style: const TextStyle(
            color: TutorialColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

// =====================================================================
// MOCK DATE SELECTOR - Seletor de data
// =====================================================================
class MockDateSelector extends StatelessWidget {
  final String displayDate;
  final bool isToday;
  final bool isHighlighted;

  const MockDateSelector({
    super.key,
    required this.displayDate,
    this.isToday = true,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: TutorialColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: TutorialColors.gold, width: 2)
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chevron_left_rounded,
            color: TutorialColors.textSecondary,
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              Text(
                displayDate,
                style: const TextStyle(
                  color: TutorialColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: TutorialColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'HOJE',
                    style: TextStyle(
                      color: TutorialColors.gold,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          const Icon(
            Icons.chevron_right_rounded,
            color: TutorialColors.textSecondary,
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// MOCK FAB - Floating Action Button
// =====================================================================
class MockFab extends StatelessWidget {
  final bool isHighlighted;
  final bool showPulse;

  const MockFab({
    super.key,
    this.isHighlighted = false,
    this.showPulse = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget fab = Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: TutorialColors.gold,
        boxShadow: [
          BoxShadow(
            color: TutorialColors.gold.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.add_rounded,
        color: Colors.black,
        size: 28,
      ),
    );

    if (showPulse) {
      return PulsingHighlight(
        color: TutorialColors.gold,
        maxScale: 1.15,
        child: fab,
      );
    }

    return fab;
  }
}

// =====================================================================
// MOCK WEEKLY DAY - Coluna de dia da semana
// =====================================================================
class MockWeeklyDay extends StatelessWidget {
  final String dayName;
  final String dayNumber;
  final bool isToday;
  final List<Widget> tasks;
  final bool isHighlighted;
  final bool showDropZone;

  const MockWeeklyDay({
    super.key,
    required this.dayName,
    required this.dayNumber,
    this.isToday = false,
    required this.tasks,
    this.isHighlighted = false,
    this.showDropZone = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: TutorialColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: TutorialColors.gold, width: 2)
            : Border.all(color: TutorialColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Header do dia
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isToday
                  ? TutorialColors.gold.withValues(alpha: 0.2)
                  : TutorialColors.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Column(
              children: [
                Text(
                  dayName,
                  style: TextStyle(
                    color: isToday ? TutorialColors.gold : TutorialColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dayNumber,
                  style: TextStyle(
                    color: isToday ? TutorialColors.gold : TutorialColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Tasks
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  ...tasks,
                  if (showDropZone) ...[
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: TutorialColors.gold,
                          style: BorderStyle.solid,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Solte aqui',
                        style: TextStyle(
                          color: TutorialColors.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// MOCK WEEKLY TASK CHIP - Chip de tarefa para weekly view
// =====================================================================
class MockWeeklyTaskChip extends StatelessWidget {
  final String title;
  final Color energyColor;
  final int durationMinutes;
  final bool isDragging;
  final bool isHighlighted;

  const MockWeeklyTaskChip({
    super.key,
    required this.title,
    required this.energyColor,
    required this.durationMinutes,
    this.isDragging = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: energyColor.withValues(alpha: isDragging ? 0.4 : 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHighlighted
              ? TutorialColors.gold
              : energyColor.withValues(alpha: 0.5),
          width: isHighlighted ? 2 : 1,
        ),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: energyColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: TutorialColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${durationMinutes}min',
            style: TextStyle(
              color: energyColor,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// MOCK DASHBOARD CHART - Gráfico de pizza simplificado
// =====================================================================
class MockDashboardChart extends StatelessWidget {
  final String title;
  final double highEnergyPercent;
  final double renewalPercent;
  final double lowEnergyPercent;
  final bool isHighlighted;

  const MockDashboardChart({
    super.key,
    required this.title,
    this.highEnergyPercent = 0.4,
    this.renewalPercent = 0.35,
    this.lowEnergyPercent = 0.25,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TutorialColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(color: TutorialColors.gold, width: 2)
            : Border.all(color: TutorialColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: TutorialColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Gráfico simplificado
              SizedBox(
                width: 80,
                height: 80,
                child: CustomPaint(
                  painter: _PieChartPainter(
                    segments: [
                      _ChartSegment(highEnergyPercent, TutorialColors.highEnergy),
                      _ChartSegment(renewalPercent, TutorialColors.renewal),
                      _ChartSegment(lowEnergyPercent, TutorialColors.lowEnergy),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Legenda
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendRow('Alta Energia', highEnergyPercent, TutorialColors.highEnergy),
                    const SizedBox(height: 8),
                    _buildLegendRow('Renovação', renewalPercent, TutorialColors.renewal),
                    const SizedBox(height: 8),
                    _buildLegendRow('Baixa Energia', lowEnergyPercent, TutorialColors.lowEnergy),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, double percent, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: TutorialColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ),
        Text(
          '${(percent * 100).toInt()}%',
          style: const TextStyle(
            color: TutorialColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ChartSegment {
  final double percent;
  final Color color;
  _ChartSegment(this.percent, this.color);
}

class _PieChartPainter extends CustomPainter {
  final List<_ChartSegment> segments;

  _PieChartPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    var startAngle = -3.14159 / 2; // Começar do topo

    for (final segment in segments) {
      final sweepAngle = segment.percent * 2 * 3.14159;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    // Centro transparente
    canvas.drawCircle(
      center,
      radius * 0.5,
      Paint()..color = TutorialColors.surface,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
