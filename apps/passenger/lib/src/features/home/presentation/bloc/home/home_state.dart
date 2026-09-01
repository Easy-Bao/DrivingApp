import 'package:equatable/equatable.dart';
import 'package:passenger/src/features/home/domain/entities/recent_location.dart';

class const HomeState({
  this.isLoading = false,
  this.currentAddress = '',
  this.locationErrorMessage = '',
  this.recentLocations = const [],
}) extends Equatable {
  final bool isLoading;
  final String currentAddress;
  final String locationErrorMessage;
  final List<RecentLocation> recentLocations;

  HomeState copyWith({
    bool? isLoading,
    String? currentAddress,
    String? locationErrorMessage,
    List<RecentLocation>? recentLocations,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      currentAddress: currentAddress ?? this.currentAddress,
      locationErrorMessage: locationErrorMessage ?? this.locationErrorMessage,
      recentLocations: recentLocations ?? this.recentLocations,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    currentAddress,
    locationErrorMessage,
    recentLocations,
  ];
}
