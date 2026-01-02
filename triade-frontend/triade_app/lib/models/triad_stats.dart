class TriadStats {
  final DateTime startDate;
  final DateTime endDate;
  final int totalMinutes;
  final double totalHours;
  final CategoryStats important;
  final CategoryStats urgent;
  final CategoryStats circumstantial;

  TriadStats({
    required this.startDate,
    required this.endDate,
    required this.totalMinutes,
    required this.totalHours,
    required this.important,
    required this.urgent,
    required this.circumstantial,
  });

  factory TriadStats.fromJson(Map<String, dynamic> json) {
    return TriadStats(
      startDate: DateTime.parse(json['period']['start']),
      endDate: DateTime.parse(json['period']['end']),
      totalMinutes: json['total_minutes'],
      totalHours: json['total_hours'].toDouble(),
      important: CategoryStats.fromJson(json['by_category']['IMPORTANT']),
      urgent: CategoryStats.fromJson(json['by_category']['URGENT']),
      circumstantial: CategoryStats.fromJson(json['by_category']['CIRCUMSTANTIAL']),
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
