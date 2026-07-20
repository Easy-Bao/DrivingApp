import 'package:core_models/core_models.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileState extends Equatable {
  final String name;
  final String phone;
  final String email;
  final bool isLoading;
  final String? errorMessage;

  const ProfileState({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.isLoading = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    String? name,
    String? phone,
    String? email,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProfileState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [name, phone, email, isLoading, errorMessage];
}

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
          emit(state.copyWith(isLoading: false, errorMessage: failure.message));
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
      debugPrint('Error syncing profile values in cubit: $error\n$stackTrace');
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: ErrorHandler.getErrorMessage(error),
        ),
      );
    }
  }
}
