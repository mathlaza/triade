class DailyConfig {
  final int id;
  final DateTime date;
  final double availableHours;

  DailyConfig({
    required this.id,
    required this.date,
    required this.availableHours,
  });

  factory DailyConfig.fromJson(Map<String, dynamic> json) {
    return DailyConfig(
      id: json['id'],
      date: DateTime.parse(json['date']),
      availableHours: json['available_hours'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'available_hours': availableHours,
    };
  }
}
