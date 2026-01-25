import 'package:flutter/material.dart';
import 'follow_up_styles.dart';

/// Card de estatísticas do Follow-up Screen
class FollowUpStatsCard extends StatelessWidget {
  final int pendingCount;
  final int overdueCount;
  final int completedCount;

  const FollowUpStatsCard({
    super.key,
    required this.pendingCount,
    required this.overdueCount,
    required this.completedCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            followUpSurfaceColor,
            followUpCardColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: followUpBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildStatItem(
            label: 'Pendentes',
            count: pendingCount,
            color: followUpWarningYellow,
            icon: Icons.schedule_rounded,
          ),
          _buildDivider(),
          _buildStatItem(
            label: 'Atrasadas',
            count: overdueCount,
            color: followUpErrorRed,
            icon: Icons.warning_rounded,
          ),
          _buildDivider(),
          _buildStatItem(
            label: 'Concluídas',
            count: completedCount,
            color: followUpSuccessGreen,
            icon: Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            count.toString(),
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: followUpTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 60,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            followUpBorderColor,
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
