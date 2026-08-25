import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  final String name;
  final String phone;
  final String email;
  final String address;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  const ProfileState({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  ProfileState copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    name,
    phone,
    email,
    address,
    isLoading,
    isSaving,
    errorMessage,
  ];
}
