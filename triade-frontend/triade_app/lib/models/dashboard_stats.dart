class DashboardStats {
  final String period;
  final DateRange dateRange;
  final int totalMinutesDone;
  final EnergyDistribution distribution;
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
      distribution: EnergyDistribution.fromJson(json['distribution']),
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

class EnergyDistribution {
  final double highEnergy;
  final double lowEnergy;
  final double renewal;

  EnergyDistribution({
    required this.highEnergy,
    required this.lowEnergy,
    required this.renewal,
  });

  factory EnergyDistribution.fromJson(Map<String, dynamic> json) {
    return EnergyDistribution(
      highEnergy: (json['HIGH_ENERGY'] ?? 0.0).toDouble(),
      lowEnergy: (json['LOW_ENERGY'] ?? 0.0).toDouble(),
      renewal: (json['RENEWAL'] ?? 0.0).toDouble(),
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