import 'package:core_models/core_models.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger_app/src/core/di/service_locator.dart';
import 'package:passenger_app/src/core/services/passenger_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// State snapshot representing the passenger profile information.
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

/// Cubit responsible for loading, caching, and syncing passenger profile details.
/// Decouples account view widgets from SharedPreferences and remote API clients.
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(const ProfileState());

  /// Loads local cached profile values for rapid paint, then refreshes and
  /// writes the latest snapshot from the API service into local storage.
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

      final profile = await getIt<PassengerApiService>().getPassengerProfile(
        passengerId,
      );
      if (profile != null) {
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
      }
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
