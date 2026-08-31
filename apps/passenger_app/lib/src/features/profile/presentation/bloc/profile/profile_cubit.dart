import 'package:passenger_app/src/features/profile/domain/entities/profile_model.dart';
import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/profile/presentation/bloc/profile/profile_state.dart';
import 'package:passenger_app/src/features/profile/domain/repositories/passenger_profile_repository.dart';
import 'package:foundation/foundation.dart';

export 'package:passenger_app/src/features/profile/presentation/bloc/profile/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final PassengerProfileRepository _repository;

  ProfileCubit({required PassengerProfileRepository repository})
    : _repository = repository,
      super(const ProfileState());

  Future<void> loadProfile() async {
    if (isClosed) return;
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final cached = _repository.getCachedProfile();

      emit(
        ProfileState(
          name: cached.name,
          phone: cached.phone,
          email: cached.email,
          address: cached.address,
          gender: cached.gender,
          avatarPath: cached.avatarPath,
          avatarUrl: cached.avatarUrl,
          avatarData: cached.avatarData,
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
          address: profile!.address,
          gender: profile!.gender,
          avatarPath: profile!.avatarPath,
          avatarUrl: profile!.avatarUrl,
          avatarData: profile!.avatarData,
          isLoading: false,
        ),
      );
    } catch (error, stackTrace) {
      dev.log(
        'Error syncing profile values in cubit.',
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: ErrorHandler.getErrorMessage(error, stackTrace),
        ),
      );
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String gender,
    required String avatarPath,
  }) async {
    if (isClosed) return false;
    emit(state.copyWith(isSaving: true, clearError: true));

    final result = await _repository.updateProfile(
      name: name,
      phone: phone,
      email: email,
      address: address,
      gender: gender,
      avatarPath: avatarPath,
    );
    if (isClosed) return false;

    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            isSaving: false,
            errorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        );
        return false;
      },
      (profile) {
        emit(
          ProfileState(
            name: profile.name,
            phone: profile.phone,
            email: profile.email,
            address: profile.address,
            gender: profile.gender.isEmpty ? gender : profile.gender,
            avatarPath: avatarPath,
            avatarUrl: profile.avatarUrl,
            avatarData: profile.avatarData,
            isSaving: false,
          ),
        );
        return true;
      },
    );
  }
}
