class EnergyStats {
  final DateTime startDate;
  final DateTime endDate;
  final int totalMinutes;
  final double totalHours;
  final CategoryStats highEnergy;
  final CategoryStats lowEnergy;
  final CategoryStats renewal;

  EnergyStats({
    required this.startDate,
    required this.endDate,
    required this.totalMinutes,
    required this.totalHours,
    required this.highEnergy,
    required this.lowEnergy,
    required this.renewal,
  });

  factory EnergyStats.fromJson(Map<String, dynamic> json) {
    return EnergyStats(
      startDate: DateTime.parse(json['period']['start']),
      endDate: DateTime.parse(json['period']['end']),
      totalMinutes: json['total_minutes'],
      totalHours: json['total_hours'].toDouble(),
      highEnergy: CategoryStats.fromJson(json['by_category']['HIGH_ENERGY']),
      lowEnergy: CategoryStats.fromJson(json['by_category']['LOW_ENERGY']),
      renewal: CategoryStats.fromJson(json['by_category']['RENEWAL']),
    );
  }
}

class CategoryStats {
  final int minutes;
  final double percentage;

  CategoryStats({
    required this.minutes,
    required this.percentage,
  });

  factory CategoryStats.fromJson(Map<String, dynamic> json) {
    return CategoryStats(
      minutes: json['minutes'],
      percentage: json['percentage'].toDouble(),
    );
  }

  double get hours => minutes / 60;
}