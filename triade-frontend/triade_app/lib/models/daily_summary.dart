class DailySummary {
  final DateTime date;
  final int totalTasks;
  final double usedHours;
  final double availableHours;
  final double remainingHours;

  DailySummary({
    required this.date,
    required this.totalTasks,
    required this.usedHours,
    required this.availableHours,
    required this.remainingHours,
  });

  factory DailySummary.fromJson(Map<String, dynamic> json) {
    return DailySummary(
      date: DateTime.parse(json['date']),
      totalTasks: json['summary']['total_tasks'],
      usedHours: json['summary']['used_hours'].toDouble(),
      availableHours: json['summary']['available_hours'].toDouble(),
      remainingHours: json['summary']['remaining_hours'].toDouble(),
    );
  }

  double get usagePercentage {
    return availableHours > 0 ? (usedHours / availableHours) * 100 : 0;
  }

  bool get isOverloaded => usedHours > availableHours;
}
