import 'package:flutter/material.dart';
import 'package:triade_app/models/task.dart';
import 'package:triade_app/config/constants.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final VoidCallback? onLongPress;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleDone;
  final bool isFutureRepeatable;
  final bool isFutureDate;

  const TaskCard({
    super.key,
    required this.task,
    this.onLongPress,
    this.onDelete,
    this.onToggleDone,
    this.isFutureRepeatable = false,
    this.isFutureDate = false,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _updateColorAnimation();
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task.status != widget.task.status) {
      _updateColorAnimation();
      if (widget.task.status == TaskStatus.done) {
        _controller.forward().then((_) => _controller.reverse());
      }
    }
  }

  void _updateColorAnimation() {
    final isDone = widget.task.status == TaskStatus.done;
    _colorAnimation = ColorTween(
      begin: const Color(0xFF2C2C2E),
      end: isDone
          ? ContextColors.completedGreen.withValues(alpha: 0.15)
          : const Color(0xFF2C2C2E),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDone = widget.task.status == TaskStatus.done;
    final isDelegated =
        widget.task.delegatedTo != null && widget.task.delegatedTo!.isNotEmpty;
    final showSeriesNumber =
        widget.task.isRepeatable && widget.task.repeatCount >= 1;

    final categoryColor = widget.task.energyLevel.color;

    return Dismissible(
      key: Key(
          '${widget.task.id}_${widget.task.dateScheduled.toIso8601String()}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.red.shade700],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1C1C1E),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Excluir tarefa?',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Tem certeza que deseja excluir "${widget.task.title}"?',
              style: const TextStyle(color: Color(0xFF98989D)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(color: Color(0xFF98989D)),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF453A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Excluir',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        if (result == true) {
          widget.onDelete?.call();
        }
        return false;
      },
      // ✅ OTIMIZAÇÃO: RepaintBoundary para isolar repaints
      child: RepaintBoundary(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedBuilder(
            animation: _colorAnimation,
            builder: (context, child) {
              return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDone
                    ? const Color(
                        0xFF1A2E1A) // Verde escuro de fundo quando DONE
                    : const Color.fromARGB(255, 49, 49, 51),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: categoryColor.withValues(alpha: isDone ? 0.6 : 0.4),
                  width: isDone ? 1.5 : 1,
                ),
                boxShadow: isDone
                    ? [
                        // Sombra da cor da energia (base, mais próxima)

                        // Brilho verde neon (mais distante, suave)
                        BoxShadow(
                          color: ContextColors.completedGreenGlow
                              .withValues(alpha: 0.4),
                          blurRadius: 5,
                          spreadRadius: 2,
                          offset: const Offset(0, 0),
                        ),
                      ]
                    : null,
              ),
              child: InkWell(
                onLongPress: () {
                  // Vibração leve ao ativar edição
                  widget.onLongPress?.call();
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (!widget.isFutureRepeatable &&
                              widget.onToggleDone != null)
                            GestureDetector(
                              onTap: widget.onToggleDone,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? ContextColors.completedGreen
                                      : const Color(0xFF3A3A3C),
                                  border: Border.all(
                                    color: isDone
                                        ? ContextColors.completedGreenGlow
                                        : const Color(0xFF48484A),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(7),
                                  boxShadow: isDone
                                      ? [
                                          BoxShadow(
                                            color: ContextColors
                                                .completedGreenGlow
                                                .withValues(alpha: 0.6),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isDone
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Color(0xFFFFFFFF),
                                      )
                                    : null,
                              ),
                            ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                decoration:
                                    isDone ? TextDecoration.lineThrough : null,
                                decorationColor: const Color(0xFF98989D),
                                decorationThickness: 2,
                                color: isDone
                                    ? const Color(
                                        0xFF98989D) // Cinza mais claro quando DONE
                                    : const Color(0xFFFFFFFF),
                                letterSpacing: -0.3,
                              ),
                              child: Text(widget.task.title),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? categoryColor.withValues(alpha: 0.25)
                                  : categoryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(
                                color: categoryColor.withValues(
                                    alpha: isDone ? 0.5 : 0.3),
                                width: isDone ? 1 : 0.5,
                              ),
                            ),
                            child: Text(
                              '${widget.task.durationMinutes}m',
                              style: TextStyle(
                                fontSize: 11,
                                color: categoryColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          // Chip de horário agendado
                          if (widget.task.scheduledTime != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? categoryColor.withValues(alpha: 0.25)
                                      : categoryColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(7),
                                  border: Border.all(
                                    color: categoryColor.withValues(
                                        alpha: isDone ? 0.5 : 0.3),
                                    width: isDone ? 1 : 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 11,
                                      color: categoryColor,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      widget.task.scheduledTime!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: categoryColor,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (_hasChips(isDelegated, showSeriesNumber))
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Chips à esquerda
                              Expanded(
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    if (widget.task.contextTag != null)
                                      _buildCompactChip(
                                        icon: Icons.label_outline,
                                        label: widget.task.contextTag!,
                                        color: ContextColors.getColor(
                                            widget.task.contextTag),
                                        isDone: isDone,
                                      ),
                                    if (widget.task.roleTag != null)
                                      _buildCompactChip(
                                        icon: Icons.person_outline,
                                        label: widget.task.roleTag!,
                                        color: Colors.blue,
                                        isDone: isDone,
                                      ),
                                    if (isDelegated)
                                      _buildCompactChip(
                                        icon: Icons.forward,
                                        label: 'Delegada',
                                        color: Colors.deepOrange,
                                        isDone: isDone,
                                      ),
                                    if (widget.task.isRepeatable)
                                      _buildCompactChip(
                                        icon: Icons.repeat,
                                        label: showSeriesNumber
                                            ? '#${widget.task.repeatCount}'
                                            : 'Rep',
                                        color: Colors.teal,
                                        isDone: isDone,
                                      ),
                                    if (widget.isFutureDate)
                                      _buildCompactChip(
                                        icon: Icons.schedule,
                                        label: 'Futuro',
                                        color: Colors.grey,
                                        isDone: isDone,
                                      ),
                                  ],
                                ),
                              ),
                              // Ícone de informação alinhado à direita
                              if (widget.task.description != null && widget.task.description!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Material(
                                    color: const Color(0xFF98989D).withValues(alpha: 0.20),
                                    shape: const CircleBorder(
                                      side: BorderSide(
                                        color: Color.fromARGB(255, 106, 106, 110),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: InkWell(
                                      onTap: () => _showDescriptionModal(context),
                                      customBorder: const CircleBorder(),
                                      splashColor: const Color(0xFF98989D).withValues(alpha: 0.3),
                                      highlightColor: const Color(0xFF98989D).withValues(alpha: 0.15),
                                      child: const Padding(
                                        padding: EdgeInsets.all(3),
                                        child: Icon(
                                          Icons.info_outline,
                                          color: Color.fromARGB(255, 106, 106, 110),
                                          size: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
            },
          ),
        ),
      ),
    );
  }

  bool _hasChips(bool isDelegated, bool showSeriesNumber) {
    return widget.task.contextTag != null ||
        widget.task.roleTag != null ||
        isDelegated ||
        widget.task.isRepeatable ||
        showSeriesNumber ||
        widget.isFutureDate ||
        widget.task.description != null;
  }

  void _showDescriptionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF38383A),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.task.energyLevel.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: widget.task.energyLevel.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.task.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.task.description ?? '',
                  style: const TextStyle(
                    color: Color(0xFFE5E5EA),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(10),
                    splashColor: const Color(0xFF98989D).withValues(alpha: 0.3),
                    highlightColor: const Color(0xFF98989D).withValues(alpha: 0.15),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: Text(
                          'Fechar',
                          style: TextStyle(
                            color: Color(0xFF98989D),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactChip({
    required IconData icon,
    required String label,
    required Color color,
    bool isDone = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDone ? 0.25 : 0.20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color, // COR SÓLIDA na borda, sem transparência!
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13), // Ícone um pouco maior
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color, // COR SÓLIDA no texto também!
              fontSize: 11,
              fontWeight: FontWeight.w700, // Mais bold
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
