import 'package:core_models/core_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:passenger_app/src/features/home/presentation/bloc/home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final PassengerHomeRepository _repository;
  double? _lastLat;
  double? _lastLng;

  HomeCubit({required PassengerHomeRepository repository})
    : _repository = repository,
      super(const HomeState());

  Future<void> loadHomeData({required double lat, required double lng}) async {
    if (_lastLat != null && _lastLng != null && state.currentAddress.isNotEmpty) {
      final deltaLat = (lat - _lastLat!).abs();
      final deltaLng = (lng - _lastLng!).abs();
      if (deltaLat < 0.0005 && deltaLng < 0.0005) {
        return;
      }
    }

    _lastLat = lat;
    _lastLng = lng;

    if (state.currentAddress.isEmpty && state.recentLocations.isEmpty) {
      emit(state.copyWith(isLoading: true));
    }
    try {
      final results = await Future.wait([
        _repository.resolveAddress(lat: lat, lng: lng),
        _repository.getRecentLocations(),
      ]);

      final addressResult = results[0] as Either<Failure, String>;
      final locationsResult =
          results[1] as Either<Failure, List<Map<String, dynamic>>>;

      String resolvedAddress = '';
      List<Map<String, dynamic>> resolvedLocations = [];

      addressResult.fold(
        (Failure failure) =>
            debugPrint('Error resolving passenger address: ${failure.message}'),
        (address) => resolvedAddress = address,
      );

      locationsResult.fold(
        (Failure failure) => debugPrint(
          'Error loading recent passenger locations: ${failure.message}',
        ),
        (locations) => resolvedLocations = locations,
      );

      emit(
        state.copyWith(
          isLoading: false,
          currentAddress: resolvedAddress,
          recentLocations: resolvedLocations,
        ),
      );
    } catch (error) {
      debugPrint('Error executing parallel home data load: $error');
      emit(state.copyWith(isLoading: false));
    }
  }

  void updateAddress(String address) {
    emit(state.copyWith(currentAddress: address));
  }
}
