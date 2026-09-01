import 'package:equatable/equatable.dart';

class const RecentLocation({
  required this.title,
  required this.subtitle,
  required this.latitude,
  required this.longitude,
}) extends Equatable {
  final String title;
  final String subtitle;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [title, subtitle, latitude, longitude];
}
