import 'package:flutter/material.dart';

class AppConstants {
  // API Base URL
  // Android Emulator: 10.0.2.2
  // iOS Simulator: localhost
  // Device físico: IP da sua máquina (ex: 192.168.1.10)

  //RODAR LOCAL:
  // static const String apiBaseUrl = 'http://10.0.2.2:5000';
  static const String apiBaseUrl = 'https://matheusew.pythonanywhere.com';

  // Cores da Tríade
  static const Color urgentColor = Color(0xFFE53935); // Vermelho
  static const Color importantColor = Color(0xFF43A047); // Verde
  static const Color circumstantialColor = Color(0xFF757575); // Cinza

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
enum TriadCategory {
  important('IMPORTANT', 'Importante', AppConstants.importantColor),
  urgent('URGENT', 'Urgente', AppConstants.urgentColor),
  circumstantial('CIRCUMSTANTIAL', 'Circunstancial', AppConstants.circumstantialColor);

  final String value;
  final String label;
  final Color color;

  const TriadCategory(this.value, this.label, this.color);

  static TriadCategory fromString(String value) {
    return TriadCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TriadCategory.circumstantial,
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
    'Reunião': Color(0xFFFF9800),       // Laranja
    'Rua': Color(0xFF4CAF50),           // Verde
    'Academia': Color(0xFFE91E63),      // Rosa
    'Casa': Color(0xFF795548),          // Marrom
    'Trabalho': Color(0xFF607D8B),      // Azul-cinza
    'Medicação': Color(0xFFF44336),     // Vermelho
  };

  static Color getColor(String? context) {
    if (context == null) return Colors.grey;
    return colors[context] ?? Colors.grey;
  }
}

