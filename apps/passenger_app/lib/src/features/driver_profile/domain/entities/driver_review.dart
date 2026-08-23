import 'package:shared_core/shared_core.dart';

class DriverReview {
  const DriverReview({
    required this.passengerName,
    required this.comment,
    required this.rating,
    this.createdAt,
  });

  factory DriverReview.fromJson(Map<String, dynamic> json) {
    return DriverReview(
      passengerName: SafeParse.toStringValue(
        json['passenger_name'] ?? json['passengerName'],
        'Passenger',
      ).trim(),
      comment: SafeParse.toStringValue(
        json['comment'] ?? json['feedback'] ?? json['message'],
      ).trim(),
      rating: SafeParse.toNullableDouble(json['rating']) ?? 0,
      createdAt: DateTime.tryParse(
        SafeParse.toStringValue(json['created_at'] ?? json['createdAt']),
      ),
    );
  }

  final String passengerName;
  final String comment;
  final double rating;
  final DateTime? createdAt;

  String get displayDate {
    final date = createdAt;
    if (date == null) return '';
    const months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
