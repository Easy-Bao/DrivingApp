import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/profile/domain/entities/passenger_profile.dart';
import 'package:passenger/src/features/profile/domain/repositories/passenger_profile_repository.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile/profile_state.dart';

export 'package:passenger/src/features/profile/presentation/bloc/profile/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required this.repository}) : super(const ProfileState());

  final PassengerProfileRepository repository;

  Future<void> loadProfile() async {
    if (isClosed || state.isLoading) return;
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final cached = repository.getCachedProfile();

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

      PassengerProfile? profile;
      Failure? failure;
      (await repository.refreshProfile()).fold(
        (value) => failure = value,
        (value) => profile = value,
      );
      if (profile == null) throw failure!;
      final resolvedProfile = profile!;

      emit(
        ProfileState(
          name: resolvedProfile.name,
          phone: resolvedProfile.phone,
          email: resolvedProfile.email,
          address: resolvedProfile.address,
          gender: resolvedProfile.gender,
          avatarPath: resolvedProfile.avatarPath,
          avatarUrl: resolvedProfile.avatarUrl,
          avatarData: resolvedProfile.avatarData,
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
    required String address,
    required String gender,
    required String avatarPath,
  }) async {
    if (isClosed) return false;
    emit(state.copyWith(isSaving: true, clearError: true));

    final result = await repository.updateProfile(
      name: name,
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
