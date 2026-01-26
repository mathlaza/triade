import 'package:flutter/material.dart';

/// Representa uma página do tutorial onboarding
class TutorialPage {
  final String title;
  final String subtitle;
  final String? description;
  final IconData? icon;
  final Widget? customContent;
  final Color accentColor;

  const TutorialPage({
    required this.title,
    this.subtitle = '',
    this.description,
    this.icon,
    this.customContent,
    this.accentColor = const Color(0xFFFFD60A),
  });
}

/// Representa um item destacável no tutorial
class TutorialHighlight {
  final String label;
  final String? description;
  final Offset position;
  final Size size;
  final bool isPulsing;
  final Color highlightColor;

  const TutorialHighlight({
    required this.label,
    this.description,
    required this.position,
    required this.size,
    this.isPulsing = true,
    this.highlightColor = const Color(0xFFFFD60A),
  });
}

/// Níveis de energia para demonstração no tutorial
enum TutorialEnergyLevel {
  highEnergy('Alta Energia', Color(0xFFE53935), Icons.bolt_rounded, '🧠'),
  renewal('Renovação', Color(0xFF43A047), Icons.battery_charging_full_rounded, '🔋'),
  lowEnergy('Baixa Energia', Color(0xFF757575), Icons.nightlight_round, '🌙');

  final String label;
  final Color color;
  final IconData icon;
  final String emoji;

  const TutorialEnergyLevel(this.label, this.color, this.icon, this.emoji);
}
