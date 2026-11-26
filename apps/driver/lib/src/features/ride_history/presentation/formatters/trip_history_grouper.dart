import 'package:driver/src/core/formatters/value_formatters.dart';
import 'package:driver/src/features/ride_history/presentation/widgets/ride_history_filter_bar.dart';

const _monthAbbreviations = <String>[
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

final class DriverTripHistoryGroups {
  const DriverTripHistoryGroups({
    required this.filteredTrips,
    required this.entries,
  });

  final List<Map<String, dynamic>> filteredTrips;
  final List<MapEntry<String, List<Map<String, dynamic>>>> entries;
}

DriverTripHistoryGroups groupDriverTrips(
  List<Map<String, dynamic>> trips,
  DriverTripHistoryFilter filter, {
  DateTime? referenceTime,
}) {
  final filtered = switch (filter) {
    DriverTripHistoryFilter.all => trips,
    DriverTripHistoryFilter.completed =>
      trips
          .where(
            (trip) =>
                (valueAsString(trip['status']) ?? '').toUpperCase() ==
                'COMPLETED',
          )
          .toList(growable: false),
    DriverTripHistoryFilter.cancelled =>
      trips
          .where((trip) {
            final status = (valueAsString(trip['status']) ?? '').toUpperCase();
            return status == 'CANCELLED' || status == 'CANCELED';
          })
          .toList(growable: false),
  };

  final now = (referenceTime ?? DateTime.now()).toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final grouped = <String, List<Map<String, dynamic>>>{};

  for (final trip in filtered) {
    final label = _formatDateGroup(
      valueAsString(trip['completed_at']) ??
          valueAsString(trip['created_at']) ??
          '',
      today: today,
      yesterday: yesterday,
    );
    grouped.putIfAbsent(label, () => []).add(trip);
  }

  return DriverTripHistoryGroups(
    filteredTrips: filtered,
    entries: grouped.entries.toList(growable: false),
  );
}

String _formatDateGroup(
  String isoString, {
  required DateTime today,
  required DateTime yesterday,
}) {
  final parsed = DateTime.tryParse(isoString)?.toLocal();
  if (parsed == null) return 'Past Trip';
  final tripDate = DateTime(parsed.year, parsed.month, parsed.day);
  if (tripDate == today) return 'Today';
  if (tripDate == yesterday) return 'Yesterday';
  return '${_monthAbbreviations[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}

String formatDriverTripClockTime(
  Map<String, dynamic> trip, {
  required bool alwaysUse24HourFormat,
}) {
  final rawDate =
      valueAsString(trip['completed_at']) ?? valueAsString(trip['created_at']);
  if (rawDate == null) return 'Past trip';
  final date = DateTime.tryParse(rawDate)?.toLocal();
  if (date == null) return 'Past trip';
  if (alwaysUse24HourFormat) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
  final hour = date.hour == 0
      ? 12
      : date.hour > 12
      ? date.hour - 12
      : date.hour;
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '$hour:${date.minute.toString().padLeft(2, '0')} $period';
}
