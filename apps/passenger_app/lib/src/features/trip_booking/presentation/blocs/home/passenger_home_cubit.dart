import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/trip_booking/presentation/blocs/home/passenger_home_state.dart';

/// Cubit responsible for managing the home screen data including resolving the current
/// address from coordinates and retrieving recent pinned target locations.
class PassengerHomeCubit extends Cubit<PassengerHomeState> {
  final PassengerHomeRepository _repository;

  PassengerHomeCubit({required PassengerHomeRepository repository})
    : _repository = repository,
      super(const PassengerHomeState());

  /// Loads the current address and recent locations in parallel.
  Future<void> loadHomeData({required double lat, required double lng}) async {
    emit(state.copyWith(isLoading: true));
    try {
      final results = await Future.wait([
        _repository.resolveAddress(lat: lat, lng: lng),
        _repository.getRecentLocations(),
      ]);
      emit(
        state.copyWith(
          isLoading: false,
          currentAddress: results[0] as String,
          recentLocations: (results[1] as List).cast<Map<String, dynamic>>(),
        ),
      );
    } catch (error) {
      debugPrint('Error loading passenger home data: $error');
      emit(state.copyWith(isLoading: false));
    }
  }

  /// Updates the displayed current address (e.g. after GPS lock).
  void updateAddress(String address) {
    emit(state.copyWith(currentAddress: address));
  }
}
