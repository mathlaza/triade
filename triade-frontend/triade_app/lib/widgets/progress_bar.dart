import 'package:flutter/material.dart';

class DailyProgressBar extends StatelessWidget {
  final double usedHours;
  final double availableHours;
  final double highEnergyHours;
  final double renewalHours;
  final double lowEnergyHours;
  final VoidCallback? onHoursTap;

  const DailyProgressBar({
    super.key,
    required this.usedHours,
    required this.availableHours,
    this.highEnergyHours = 0,
    this.renewalHours = 0,
    this.lowEnergyHours = 0,
    this.onHoursTap,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = availableHours > 0 ? usedHours / availableHours : 0.0;
    final isOverloaded = usedHours > availableHours;

    final highEnergyPercentage =
        availableHours > 0 ? highEnergyHours / availableHours : 0.0;
    final renewalPercentage =
        availableHours > 0 ? renewalHours / availableHours : 0.0;
    final lowEnergyPercentage =
        availableHours > 0 ? lowEnergyHours / availableHours : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              isOverloaded ? const Color(0xFFFF453A) : const Color(0xFF38383A),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD60A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.analytics_outlined,
                      color: Color(0xFF000000),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Capacidade',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              Material(
                color: isOverloaded
                    ? const Color(0xFFFF453A)
                    : const Color(0xFFFFD60A),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: onHoursTap,
                  borderRadius: BorderRadius.circular(8),
                  splashColor: const Color(0xFF98989D).withValues(alpha: 0.3),
                  highlightColor: const Color(0xFF98989D).withValues(alpha: 0.15),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${usedHours.toStringAsFixed(1)}h / ${availableHours.toStringAsFixed(1)}h',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF000000),
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (onHoursTap != null) ...[
                          const SizedBox(width: 4),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF2C2C2E),
                    ),
                  ),
                  Row(
                    children: [
                      if (highEnergyPercentage > 0)
                        Flexible(
                          flex: (highEnergyPercentage * 100).round(),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFFF453A),
                            ),
                          ),
                        ),
                      if (renewalPercentage > 0)
                        Flexible(
                          flex: (renewalPercentage * 100).round(),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF30D158),
                            ),
                          ),
                        ),
                      if (lowEnergyPercentage > 0)
                        Flexible(
                          flex: (lowEnergyPercentage * 100).round(),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFF98989D),
                            ),
                          ),
                        ),
                      if (percentage < 1.0)
                        Flexible(
                          flex: ((1.0 - percentage) * 100).round(),
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isOverloaded) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF453A).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF453A).withValues(alpha: 0.3),
                  width: 0.5,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFFF453A),
                    size: 13,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Capacidade excedida',
                    style: TextStyle(
                      color: Color(0xFFFF453A),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (highEnergyHours > 0 ||
              renewalHours > 0 ||
              lowEnergyHours > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (highEnergyHours > 0)
                  _buildLegendItem(
                    color: const Color(0xFFFF453A),
                    label: 'Alta',
                    hours: highEnergyHours,
                  ),
                if (renewalHours > 0) ...[
                  if (highEnergyHours > 0) const SizedBox(width: 10),
                  _buildLegendItem(
                    color: const Color(0xFF30D158),
                    label: 'Renovação',
                    hours: renewalHours,
                  ),
                ],
                if (lowEnergyHours > 0) ...[
                  if (highEnergyHours > 0 || renewalHours > 0)
                    const SizedBox(width: 10),
                  _buildLegendItem(
                    color: const Color(0xFF98989D),
                    label: 'Baixa',
                    hours: lowEnergyHours,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required double hours,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ${hours.toStringAsFixed(1)}h',
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF98989D),
            fontWeight: FontWeight.w500,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}
