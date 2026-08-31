import 'package:passenger_app/src/features/active_ride/active_ride.dart';
import 'package:passenger_app/src/features/activity/activity.dart';
import 'package:shared_core/shared_core.dart';

class PassengerActivityHistoryPresenter {
  final DateTime referenceTime;

  PassengerActivityHistoryPresenter(DateTime referenceTime)
    : referenceTime = referenceTime.toLocal();

  List<RideHistory> sortPastRides(List<RideHistory> rides) {
    final sorted = List<RideHistory>.of(rides);
    sorted.sort((left, right) {
      final leftDate = _parseMoment(left.date).dateTime;
      final rightDate = _parseMoment(right.date).dateTime;
      if (leftDate == null && rightDate == null) return 0;
      if (leftDate == null) return 1;
      if (rightDate == null) return -1;
      return rightDate.compareTo(leftDate);
    });
    return sorted;
  }

  Map<String, List<RideHistory>> groupRides(List<RideHistory> rides) {
    final grouped = <String, List<RideHistory>>{};
    for (final ride in rides) {
      grouped.putIfAbsent(dateGroupLabel(ride.date), () => []).add(ride);
    }
    return grouped;
  }

  List<RideHistory> completedRidesThisWeek(List<RideHistory> rides) {
    final day = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
    );
    final weekStart = day.subtract(Duration(days: day.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    return rides.where((ride) {
      if (RideStatus.fromString(ride.status) != RideStatus.completed) {
        return false;
      }
      final date = _parseMoment(ride.date).dateTime;
      return date != null &&
          !date.isBefore(weekStart) &&
          date.isBefore(weekEnd);
    }).toList();
  }

  String dateGroupLabel(String rawDate) {
    final date = _parseMoment(rawDate).dateTime;
    if (date == null) return 'Date unavailable';

    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(
      referenceTime.year,
      referenceTime.month,
      referenceTime.day,
    );
    final shortDate = '${_monthNames[date.month - 1]} ${date.day}';
    if (day == today) return 'Today · $shortDate';
    if (day == today.subtract(const Duration(days: 1))) {
      return 'Yesterday · $shortDate';
    }
    if (date.year != referenceTime.year) return '$shortDate, ${date.year}';
    return '${_weekdayNames[date.weekday - 1]} · $shortDate';
  }

  String rideMetadata(RideHistory ride) {
    final moment = _parseMoment(ride.date);
    final values = <String>[
      if (moment.hasTime && moment.dateTime != null)
        _formatClockTime(moment.dateTime!),
      rideTypeLabel(ride),
    ];
    return values.where((value) => value.isNotEmpty).join(' · ');
  }

  _RideMoment _parseMoment(String rawDate) {
    final value = rawDate.trim();
    if (value.isEmpty) return const _RideMoment();

    final isoDate = DateTime.tryParse(value);
    if (isoDate != null) {
      return _RideMoment(
        dateTime: isoDate.toLocal(),
        hasTime: RegExp(r'[T ]\d{1,2}:\d{2}').hasMatch(value),
      );
    }

    final match = RegExp(
      r'^([A-Za-z]{3})\s+(\d{1,2})(?:,\s*(\d{1,2}):(\d{2})\s*(AM|PM))?$',
      caseSensitive: false,
    ).firstMatch(value);
    if (match == null) return const _RideMoment();

    final month = _monthNames.indexWhere(
      (name) => name.toLowerCase() == match.group(1)!.toLowerCase(),
    );
    if (month < 0) return const _RideMoment();

    final day = int.tryParse(match.group(2)!);
    final rawHour = int.tryParse(match.group(3) ?? '0');
    final minute = int.tryParse(match.group(4) ?? '0');
    if (day == null || rawHour == null || minute == null) {
      return const _RideMoment();
    }

    var hour = rawHour;
    final period = match.group(5)?.toUpperCase();
    if (period != null) {
      hour %= 12;
      if (period == 'PM') hour += 12;
    }

    var parsed = DateTime(referenceTime.year, month + 1, day, hour, minute);
    if (parsed.isAfter(referenceTime.add(const Duration(days: 1)))) {
      parsed = DateTime(referenceTime.year - 1, month + 1, day, hour, minute);
    }

    return _RideMoment(dateTime: parsed, hasTime: match.group(3) != null);
  }

  double priceValue(String price) {
    final normalized = price.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  String rideTypeLabel(RideHistory ride) {
    final vehicleType = ride.vehicleType.trim().toLowerCase();
    if (vehicleType.isEmpty) return '';
    return vehicleType.contains('share') ? 'Shared ride' : 'Solo ride';
  }

  String destinationLabel(RideHistory ride) {
    final destination = ride.destination.trim();
    return destination.isEmpty ? 'Destination unavailable' : destination;
  }

  String fareLabel(RideHistory ride) {
    final fare = ride.price.trim();
    if (fare.isEmpty) return '—';
    final normalized = fare.replaceAll(RegExp(r'[^0-9.\-]'), '');
    final amount = double.tryParse(normalized);
    return amount == null ? '—' : formatPesoAmount(amount);
  }

  String _formatClockTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}

class _RideMoment {
  final DateTime? dateTime;
  final bool hasTime;

  const _RideMoment({this.dateTime, this.hasTime = false});
}

const _monthNames = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const _weekdayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
