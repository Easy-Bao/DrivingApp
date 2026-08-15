import 'package:equatable/equatable.dart';
import 'package:passenger_app/src/features/home/domain/entities/recent_location.dart';

class HomeData extends Equatable {
  HomeData({
    required this.currentAddress,
    required List<RecentLocation> recentLocations,
  }) : recentLocations = List.unmodifiable(recentLocations);

  final String currentAddress;
  final List<RecentLocation> recentLocations;

  @override
  List<Object?> get props => [currentAddress, recentLocations];
}
