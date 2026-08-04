import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/features/booking/data/data_sources/passenger_remote_data_source.dart';
import 'package:passenger_app/src/features/profile/presentation/bloc/profile_state.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:passenger_app/src/features/profile/presentation/bloc/profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final PassengerRemoteDataSource _remoteDataSource;
  final SecureSessionService _secureSessionService;

  ProfileCubit({
    required PassengerRemoteDataSource remoteDataSource,
    required SecureSessionService secureSessionService,
  }) : _remoteDataSource = remoteDataSource,
       _secureSessionService = secureSessionService,
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

      final passengerId = await _secureSessionService.readPassengerId() ?? '';
      if (passengerId.isEmpty) return;

      final profile = await _remoteDataSource.fetchPassengerProfile(
        passengerId,
      );
      final name = profile['name'] as String? ?? cachedName;
      final phone = profile['phone'] as String? ?? cachedPhone;
      final email = profile['email'] as String? ?? cachedEmail;

      await prefs.setString('passenger_name', name);
      await prefs.setString('passenger_phone', phone);
      await prefs.setString('passenger_email', email);

      emit(
        ProfileState(name: name, phone: phone, email: email, isLoading: false),
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
