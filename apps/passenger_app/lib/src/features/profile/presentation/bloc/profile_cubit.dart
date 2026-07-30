import 'dart:developer' as dev;

import 'package:core_models/core_models.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/features/profile/presentation/bloc/profile_state.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:passenger_app/src/features/profile/presentation/bloc/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final PassengerProfileRepository _profileRepository;

  ProfileCubit({required PassengerProfileRepository profileRepository})
      : _profileRepository = profileRepository,
        super(const ProfileState());

  Future<void> loadProfile() async {
    emit(state.copyWith(isLoading: true));

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('passenger_name') ?? '';
      final cachedPhone = prefs.getString('passenger_phone') ?? '';
      final cachedEmail = prefs.getString('passenger_email') ?? '';

      emit(
        ProfileState(
          name: cachedName,
          phone: cachedPhone,
          email: cachedEmail,
          isLoading: false,
        ),
      );

      final passengerId = prefs.getString('passenger_id') ?? '';
      if (passengerId.isEmpty) return;

      final result = await _profileRepository.getPassengerProfile(passengerId);
      await result.fold(
        (failure) async {
          emit(
            state.copyWith(isLoading: false, errorMessage: failure.message),
          );
        },
        (profile) async {
          final name = profile['name'] as String? ?? cachedName;
          final phone = profile['phone'] as String? ?? cachedPhone;
          final email = profile['email'] as String? ?? cachedEmail;

          await prefs.setString('passenger_name', name);
          await prefs.setString('passenger_phone', phone);
          await prefs.setString('passenger_email', email);

          emit(
            ProfileState(
              name: name,
              phone: phone,
              email: email,
              isLoading: false,
            ),
          );
        },
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
