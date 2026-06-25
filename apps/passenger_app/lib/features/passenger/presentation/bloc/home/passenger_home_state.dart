import 'package:equatable/equatable.dart';
import 'package:fixtures/fixtures.dart';

/**
 * Immutable state for the passenger home screen.
 */
class PassengerHomeState extends Equatable {
  final bool isLoading;
  final String currentAddress;
  final List<Map<String, dynamic>> recentLocations;

  const PassengerHomeState({
    this.isLoading = false,
    this.currentAddress = MockData.defaultAddress,
    this.recentLocations = const [],
  });

  PassengerHomeState copyWith({
    bool? isLoading,
    String? currentAddress,
    List<Map<String, dynamic>>? recentLocations,
  }) {
    return PassengerHomeState(
      isLoading: isLoading ?? this.isLoading,
      currentAddress: currentAddress ?? this.currentAddress,
      recentLocations: recentLocations ?? this.recentLocations,
    );
  }

  @override
  List<Object?> get props => [isLoading, currentAddress, recentLocations];
}
