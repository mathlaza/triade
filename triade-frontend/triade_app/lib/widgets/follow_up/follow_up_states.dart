import 'package:flutter/material.dart';
import 'follow_up_styles.dart';

/// Estado de carregamento do Follow-up Screen
class FollowUpLoadingState extends StatelessWidget {
  const FollowUpLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: followUpCardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: followUpBorderColor),
            ),
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(followUpAccentGold),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Carregando delegações...',
            style: TextStyle(
              color: followUpTextSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estado de erro do Follow-up Screen
class FollowUpErrorState extends StatelessWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const FollowUpErrorState({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: followUpErrorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: followUpErrorRed.withValues(alpha: 0.3)),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: followUpErrorRed,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ops! Algo deu errado',
              style: TextStyle(
                color: followUpTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: followUpTextSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: followUpAccentGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text(
                'Tentar Novamente',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vazio do Follow-up Screen
class FollowUpEmptyState extends StatelessWidget {
  const FollowUpEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    followUpAccentGold.withValues(alpha: 0.2),
                    followUpAccentOrange.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: followUpAccentGold.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.groups_outlined,
                color: followUpAccentGold,
                size: 64,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Nenhuma Delegação',
              style: TextStyle(
                color: followUpTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Você ainda não delegou nenhuma tarefa.\nDelegue tarefas para acompanhá-las aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: followUpTextSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: followUpCardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: followUpBorderColor),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: followUpAccentGold,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Ao criar uma tarefa, preencha\no campo "Delegada para"',
                      style: TextStyle(
                        color: followUpTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
