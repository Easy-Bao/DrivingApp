import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/profile/domain/repositories/profile_repository.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile_state.dart';

export 'package:passenger/src/features/profile/presentation/bloc/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit({required this.repository}) : super(const ProfileState());

  final ProfileRepository repository;
  int _loadVersion = 0;

  void reset() {
    _loadVersion++;
    repository.clearCachedProfile();
    if (!isClosed) {
      emit(const ProfileState());
    }
  }

  Future<void> loadProfile({bool refreshRemote = true}) async {
    if (isClosed || state.isLoading) return;
    final version = ++_loadVersion;
    emit(state.copyWith(isLoading: true, clearError: true));

    try {
      final cached = repository.getCachedProfile();
      if (isClosed || version != _loadVersion) return;

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
          isLoading: refreshRemote,
        ),
      );

      if (!refreshRemote) return;

      final result = await repository.refreshProfile();
      if (isClosed || version != _loadVersion) return;

      switch (result) {
        case Err(:final failure):
          emit(
            state.copyWith(
              isLoading: false,
              errorMessage: ErrorHandler.getErrorMessage(failure),
            ),
          );
        case Ok(:final value):
          emit(
            ProfileState(
              name: value.name,
              phone: value.phone,
              email: value.email,
              address: value.address,
              gender: value.gender,
              avatarPath: value.avatarPath,
              avatarUrl: value.avatarUrl,
              avatarData: value.avatarData,
              isLoading: false,
            ),
          );
      }
    } catch (error, stackTrace) {
      dev.log(
        'Error syncing profile values in cubit.',
        error: error,
        stackTrace: stackTrace,
      );
      if (isClosed || version != _loadVersion) return;
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
    final version = ++_loadVersion;
    emit(state.copyWith(isSaving: true, clearError: true));

    final result = await repository.updateProfile(
      name: name,
      address: address,
      gender: gender,
      avatarPath: avatarPath,
    );
    if (isClosed || version != _loadVersion) return false;

    switch (result) {
      case Err(:final failure):
        emit(
          state.copyWith(
            isSaving: false,
            errorMessage: ErrorHandler.getErrorMessage(failure),
          ),
        );
        return false;
      case Ok(:final value):
        emit(
          ProfileState(
            name: value.name,
            phone: value.phone,
            email: value.email,
            address: value.address,
            gender: value.gender.isEmpty ? gender : value.gender,
            avatarPath: avatarPath,
            avatarUrl: value.avatarUrl,
            avatarData: value.avatarData,
            isSaving: false,
          ),
        );
        return true;
    }
  }
}
