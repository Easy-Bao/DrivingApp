import 'package:equatable/equatable.dart';
import 'package:foundation/foundation.dart';

enum EarningsPeriod { daily, weekly, monthly }

class EarningsSummary extends Equatable {
  const EarningsSummary({
    required this.daily,
    required this.weekly,
    required this.monthly,
    this.raw = const {},
  });

  final EarningsPeriodSummary daily;
  final EarningsPeriodSummary weekly;
  final EarningsPeriodSummary monthly;
  final Map<String, dynamic> raw;

  EarningsPeriodSummary summaryFor(EarningsPeriod period) {
    switch (period) {
      case EarningsPeriod.daily:
        return daily;
      case EarningsPeriod.weekly:
        return weekly;
      case EarningsPeriod.monthly:
        return monthly;
    }
  }

  factory EarningsSummary.fromJson(
    Map<String, dynamic> data, [
    DateTime? referenceDate,
  ]) {
    final today = _parsePeriod(data['today']);
    final week = _parsePeriod(data['this_week']);
    final month = _parsePeriod(data['this_month']);
    final now = referenceDate ?? DateTime.now();

    final weekdays = _parseBuckets(
      data['weekdays'],
      (index, date) => _weekdayLabel(date?.weekday ?? index + 1),
      now,
    );

    final monthWeeks = _parseBuckets(
      data['month_weeks'],
      (index, _) => 'W${index + 1}',
      now,
      currentIndex: (now.day - 1) ~/ 7,
    );

    return EarningsSummary(
      daily: EarningsPeriodSummary(
        total: today.total,
        tripsCount: today.tripsCount,
        days: [
          EarnDayBucket(day: 'Today', amount: today.total, isCurrent: true),
        ],
      ),
      weekly: EarningsPeriodSummary(
        total: week.total,
        tripsCount: week.tripsCount,
        days: weekdays,
      ),
      monthly: EarningsPeriodSummary(
        total: month.total,
        tripsCount: month.tripsCount,
        days: monthWeeks,
      ),
      raw: data,
    );
  }

  static EarningsPeriodSummary _parsePeriod(Object? raw) {
    final data = raw is Map
        ? Map<String, dynamic>.from(raw)
        : const <String, dynamic>{};
    return EarningsPeriodSummary(
      total: SafeParse.toDouble(data['earnings_amount']) / 100,
      tripsCount: SafeParse.toInt(data['completed_trips']),
      days: const [],
    );
  }

  static List<EarnDayBucket> _parseBuckets(
    Object? raw,
    String Function(int index, DateTime? date) label,
    DateTime now, {
    int? currentIndex,
  }) {
    if (raw is! List) return const [];
    return [
      for (var index = 0; index < raw.length; index++)
        if (raw[index] is Map)
          _bucketDay(
            Map<String, dynamic>.from(raw[index] as Map),
            label,
            index,
            now,
            currentIndex,
          ),
    ];
  }

  static EarnDayBucket _bucketDay(
    Map<String, dynamic> bucket,
    String Function(int index, DateTime? date) label,
    int index,
    DateTime now,
    int? currentIndex,
  ) {
    final date = DateTime.tryParse(
      SafeParse.toStringValue(bucket['start_date']),
    );
    return EarnDayBucket(
      day: label(index, date),
      amount: SafeParse.toDouble(bucket['earnings_amount']) / 100,
      isCurrent: currentIndex == index || (date != null && _sameDay(date, now)),
    );
  }

  static String _weekdayLabel(int weekday) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday < 1 || weekday > 7) return '—';
    return labels[weekday - 1];
  }

  static bool _sameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;

  @override
  List<Object?> get props => [daily, weekly, monthly];
}

class EarningsPeriodSummary extends Equatable {
  const EarningsPeriodSummary({
    required this.total,
    required this.tripsCount,
    required this.days,
  });

  final double total;
  final int tripsCount;
  final List<EarnDayBucket> days;

  @override
  List<Object?> get props => [total, tripsCount, days];
}

class EarnDayBucket extends Equatable {
  const EarnDayBucket({
    required this.day,
    required this.amount,
    this.isCurrent = false,
  });

  final String day;
  final double amount;
  final bool isCurrent;

  @override
  List<Object?> get props => [day, amount, isCurrent];
}
