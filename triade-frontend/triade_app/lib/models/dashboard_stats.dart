class DashboardStats {
  final String period;
  final DateRange dateRange;
  final int totalMinutesDone;
  final TriadDistribution distribution;
  final Insight insight;

  DashboardStats({
    required this.period,
    required this.dateRange,
    required this.totalMinutesDone,
    required this.distribution,
    required this.insight,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      period: json['period'],
      dateRange: DateRange.fromJson(json['date_range']),
      totalMinutesDone: json['total_minutes_done'],
      distribution: TriadDistribution.fromJson(json['distribution']),
      insight: Insight.fromJson(json['insight']),
    );
  }

  double get totalHoursDone => totalMinutesDone / 60.0;
}

class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  factory DateRange.fromJson(Map<String, dynamic> json) {
    return DateRange(
      start: DateTime.parse(json['start']),
      end: DateTime.parse(json['end']),
    );
  }
}

class TriadDistribution {
  final double important;
  final double urgent;
  final double circumstantial;

  TriadDistribution({
    required this.important,
    required this.urgent,
    required this.circumstantial,
  });

  factory TriadDistribution.fromJson(Map<String, dynamic> json) {
    return TriadDistribution(
      important: (json['IMPORTANT'] ?? 0.0).toDouble(),
      urgent: (json['URGENT'] ?? 0.0).toDouble(),
      circumstantial: (json['CIRCUMSTANTIAL'] ?? 0.0).toDouble(),
    );
  }
}

class Insight {
  final String type;
  final String title;
  final String message;
  final String colorHex;

  Insight({
    required this.type,
    required this.title,
    required this.message,
    required this.colorHex,
  });

  factory Insight.fromJson(Map<String, dynamic> json) {
    return Insight(
      type: json['type'],
      title: json['title'],
      message: json['message'],
      colorHex: json['color_hex'],
    );
  }
}