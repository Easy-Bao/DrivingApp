import 'package:equatable/equatable.dart';
import 'package:passenger_app/src/features/home/domain/entities/recent_location.dart';

class HomeState extends Equatable {
  final bool isLoading;
  final String currentAddress;
  final List<RecentLocation> recentLocations;

  const HomeState({
    this.isLoading = false,
    this.currentAddress = '',
    this.recentLocations = const [],
  });

  HomeState copyWith({
    bool? isLoading,
    String? currentAddress,
    List<RecentLocation>? recentLocations,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      currentAddress: currentAddress ?? this.currentAddress,
      recentLocations: recentLocations ?? this.recentLocations,
    );
  }

  @override
  List<Object?> get props => [isLoading, currentAddress, recentLocations];
}
