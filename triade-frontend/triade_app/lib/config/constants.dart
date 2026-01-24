import 'package:flutter/material.dart';

class AppConstants {
  // API Base URL
  // Android Emulator: 10.0.2.2
  // iOS Simulator: localhost
  // Device físico: IP da sua máquina (ex: 192.168.1.10)

  //RODAR LOCAL:
  // static const String apiBaseUrl = 'http://10.0.2.2:5000';
  static const String apiBaseUrl = 'https://matheusew.pythonanywhere.com';

  // Cores dos Níveis de Energia
  static const Color highEnergyColor = Color(0xFFE53935); // Vermelho (Alta Energia)
  static const Color lowEnergyColor = Color(0xFF757575); // Cinza (Baixa Energia)
  static const Color renewalColor = Color(0xFF43A047); // Verde (Renovação)

  // Cores auxiliares
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;

  // Formatos de data
  static const String dateFormat = 'yyyy-MM-dd';
  static const String displayDateFormat = 'dd/MM/yyyy';

  // Limites
  static const int maxDailyHours = 16;
  static const int minTaskDuration = 5;
}

// Enum para categorias da Tríade
enum EnergyLevel {
  highEnergy('HIGH_ENERGY', '🧠 Alta Energia', AppConstants.highEnergyColor),
  lowEnergy('LOW_ENERGY', '⚡ Baixa Energia', Color.fromARGB(255, 133, 133, 133)),
  renewal('RENEWAL', '🔋 Renovação', AppConstants.renewalColor);

  final String value;
  final String label;
  final Color color;

  const EnergyLevel(this.value, this.label, this.color);

  static EnergyLevel fromString(String value) {
    return EnergyLevel.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EnergyLevel.lowEnergy,
    );
  }
}

// Enum para status da tarefa
enum TaskStatus {
  active('ACTIVE', 'Ativa'),
  done('DONE', 'Concluída'),
  delegated('DELEGATED', 'Delegada'),
  pendingReview('PENDING_REVIEW', 'Revisão Pendente');

  final String value;
  final String label;

  const TaskStatus(this.value, this.label);

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskStatus.active,
    );
  }
}

// Contextos disponíveis
class ContextTags {
  static const List<String> options = [
    'Computador',
    'Telefone',
    'Reunião',
    'Rua',
    'Academia',
    'Casa',
    'Trabalho',
    'Medicação',
  ];
}



// Cores dos Contextos
class ContextColors {
  static const Map<String, Color> colors = {
    'Computador': Color(0xFF9C27B0),    // Roxo
    'Telefone': Color(0xFF2196F3),      // Azul
    'Reunião': Color.fromARGB(255, 227, 136, 0),       // Laranja
    'Rua': Color.fromARGB(255, 12, 75, 13),           // Verde
    'Academia': Color(0xFFE91E63),      // Rosa
    'Casa': Color(0xFF795548),          // Marrom
    'Trabalho': Color(0xFF607D8B),      // Azul-cinza
    'Medicação': Color(0xFFF44336),     // Vermelho
  };

  static Color getColor(String? context) {
    if (context == null) return Colors.grey;
    return colors[context] ?? Colors.grey;
  }


  // Cores do tema premium
  static const Color darkBackground = Color(0xFF000000);
  static const Color cardBackground = Color(0xFF1C1C1E);
  static const Color elevatedCardBackground = Color(0xFF2C2C2E);
  static const Color borderColor = Color(0xFF38383A);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF98989D);
  static const Color accentGold = Color(0xFFFFD60A);
  static const Color completedGreen = Color(0xFF30D158);
  static const Color completedGreenGlow = Color(0xFF32D74B);
}

