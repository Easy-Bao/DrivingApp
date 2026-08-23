import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/profile/bloc/profile/profile_state.dart';
import 'package:passenger_app/src/features/profile/domain/repositories/i_passenger_profile_repository.dart';
import 'package:shared_core/shared_core.dart';

export 'package:passenger_app/src/features/profile/bloc/profile/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final IPassengerProfileRepository _repository;

  ProfileCubit({required IPassengerProfileRepository repository})
    : _repository = repository,
      super(const ProfileState());

  Future<void> loadProfile() async {
    emit(state.copyWith(isLoading: true));

    try {
      final cached = _repository.getCachedProfile();

      emit(
        ProfileState(
          name: cached.name,
          phone: cached.phone,
          email: cached.email,
          isLoading: false,
        ),
      );

      ProfileModel? profile;
      Failure? failure;
      (await _repository.refreshProfile()).fold(
        (value) => failure = value,
        (value) => profile = value,
      );
      if (profile == null) throw failure!;

      emit(
        ProfileState(
          name: profile!.name,
          phone: profile!.phone,
          email: profile!.email,
          isLoading: false,
        ),
      );
    } catch (error, stackTrace) {
      dev.log('Error syncing profile values in cubit: $error\n$stackTrace');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }
}
