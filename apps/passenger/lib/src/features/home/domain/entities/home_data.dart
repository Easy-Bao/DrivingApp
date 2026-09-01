import 'package:equatable/equatable.dart';
import 'package:passenger/src/features/home/domain/entities/recent_location.dart';

class const HomeData({
  required this.currentAddress,
  required this.recentLocations,
}) extends Equatable {
  new fromList({
    required String currentAddress,
    required List<RecentLocation> recentLocations,
  }) : this(
         currentAddress: currentAddress,
         recentLocations: List.unmodifiable(recentLocations),
       );

  final String currentAddress;
  final List<RecentLocation> recentLocations;

  @override
  List<Object?> get props => [currentAddress, recentLocations];
}
