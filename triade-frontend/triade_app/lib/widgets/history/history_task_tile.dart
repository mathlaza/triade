import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/history_task.dart';

/// Tile de tarefa do histórico com design premium
class HistoryTaskTile extends StatelessWidget {
  final HistoryTask task;
  final VoidCallback? onTap;

  const HistoryTaskTile({
    super.key,
    required this.task,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x26FFFFFF),
            Color(0x14FFFFFF),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0x33FFFFFF),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ?? () => _showTaskDetailModal(context),
          borderRadius: BorderRadius.circular(10),
          splashColor: const Color(0x33FFD700),
          highlightColor: const Color(0x1AFFD700),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                // Indicador de categoria
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: task.energyLevel.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: task.energyLevel.color.withValues(alpha: 0.8),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              task.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildPerformanceIndicator(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 11,
                            color: Color(0xFFFFD700),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            task.formattedDuration,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFE5E7EB),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (task.contextTag != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFA500),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                task.contextTag!,
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: Color(0xFF1A1A2E),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFFFFD700),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceIndicator() {
    final indicator = task.performanceIndicator;

    if (indicator == PerformanceIndicator.onTime) {
      return const SizedBox.shrink();
    }

    final isAnticipated = indicator == PerformanceIndicator.anticipated;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAnticipated ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isAnticipated ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAnticipated ? Icons.flash_on : Icons.schedule,
            size: 12,
            color: isAnticipated ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 2),
          Text(
            isAnticipated ? 'Antecipada' : 'Atrasada',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color:
                  isAnticipated ? Colors.green.shade700 : Colors.orange.shade700,
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetailModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => HistoryTaskDetailModal(task: task),
    );
  }
}

/// Modal de detalhes da tarefa do histórico
class HistoryTaskDetailModal extends StatelessWidget {
  final HistoryTask task;

  const HistoryTaskDetailModal({
    super.key,
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Color(0x80000000),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Barra de arrasto
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header compacto
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: task.energyLevel.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: task.energyLevel.color.withValues(alpha: 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),

            // Descrição (se existir)
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0x33FFFFFF),
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        task.description!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFE5E7EB),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Grid compacto 2 colunas
            Row(
              children: [
                Expanded(
                  child: _buildCompactDetail(
                    Icons.category_outlined,
                    task.energyLevel.label,
                    task.energyLevel.color,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCompactDetail(
                    Icons.timer_outlined,
                    task.formattedDuration,
                    const Color(0xFFFFD700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildCompactDetail(
                    Icons.check_circle_outline,
                    DateFormat('dd/MM HH:mm', 'pt_BR').format(task.completedAt),
                    const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildCompactDetail(
                    Icons.event_outlined,
                    DateFormat('dd/MM/yyyy', 'pt_BR').format(task.dateScheduled),
                    const Color(0xFF2196F3),
                  ),
                ),
              ],
            ),
            if (task.contextTag != null || task.roleTag != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (task.contextTag != null)
                    Expanded(
                      child: _buildCompactDetail(
                        Icons.label_outline,
                        task.contextTag!,
                        const Color(0xFFFF9800),
                      ),
                    ),
                  if (task.contextTag != null && task.roleTag != null)
                    const SizedBox(width: 10),
                  if (task.roleTag != null)
                    Expanded(
                      child: _buildCompactDetail(
                        Icons.person_outline,
                        task.roleTag!,
                        const Color(0xFF9C27B0),
                      ),
                    ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Botão compacto
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(
                      color: Color(0xFF1A1A2E),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDetail(IconData icon, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x1AFFFFFF), Color(0x0DFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accentColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
