import 'package:flutter/material.dart';
import 'follow_up_styles.dart';

/// Header premium do Follow-up Screen com botão voltar e título
class FollowUpHeader extends StatelessWidget {
  const FollowUpHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [followUpSurfaceColor, followUpBackgroundColor],
        ),
      ),
      child: Row(
        children: [
          // Botão voltar premium
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: followUpCardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: followUpBorderColor),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: followUpTextPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Título
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [followUpAccentGold, followUpAccentOrange],
                  ).createShader(bounds),
                  child: const Text(
                    'Follow-up',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const Text(
                  'Acompanhe suas delegações',
                  style: TextStyle(
                    color: followUpTextSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          // Ícone decorativo
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [followUpAccentGold, followUpAccentOrange],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: followUpAccentGold.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.black,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
