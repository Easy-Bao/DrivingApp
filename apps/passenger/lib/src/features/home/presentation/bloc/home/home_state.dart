import 'package:equatable/equatable.dart';
import 'package:passenger/src/features/home/domain/entities/recent_location.dart';

class const HomeState({
  this.isLoading = false,
  this.currentAddress = '',
  this.locationErrorMessage = '',
  this.recentLocations = const [],
  this.nearbyPlaceNames = const [],
}) extends Equatable {
  final bool isLoading;
  final String currentAddress;
  final String locationErrorMessage;
  final List<RecentLocation> recentLocations;
  final List<String> nearbyPlaceNames;

  HomeState copyWith({
    bool? isLoading,
    String? currentAddress,
    String? locationErrorMessage,
    List<RecentLocation>? recentLocations,
    List<String>? nearbyPlaceNames,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      currentAddress: currentAddress ?? this.currentAddress,
      locationErrorMessage: locationErrorMessage ?? this.locationErrorMessage,
      recentLocations: recentLocations ?? this.recentLocations,
      nearbyPlaceNames: nearbyPlaceNames ?? this.nearbyPlaceNames,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    currentAddress,
    locationErrorMessage,
    recentLocations,
    nearbyPlaceNames,
  ];
}
