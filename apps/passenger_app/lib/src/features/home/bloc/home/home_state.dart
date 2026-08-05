import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final bool isLoading;
  final String currentAddress;
  final List<Map<String, dynamic>> recentLocations;

  const HomeState({
    this.isLoading = false,
    this.currentAddress = '',
    this.recentLocations = const [],
  });

  HomeState copyWith({
    bool? isLoading,
    String? currentAddress,
    List<Map<String, dynamic>>? recentLocations,
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
