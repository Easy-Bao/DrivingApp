import 'package:equatable/equatable.dart';
import 'package:passenger/src/features/home/domain/entities/recent_location.dart';

class HomeData({
  required this.currentAddress,
  required List<RecentLocation> recentLocations,
}) extends Equatable {
  this : recentLocations = List.unmodifiable(recentLocations);

  final String currentAddress;
  final List<RecentLocation> recentLocations;

  @override
  List<Object?> get props => [currentAddress, recentLocations];
}
