import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:image_picker/image_picker.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/profile/bloc/profile/profile_cubit.dart';
import 'package:passenger_app/src/features/profile/view/widgets/profile_avatar_widget.dart';
import 'package:shared_ui/shared_ui.dart';

class ProfileInfoPage extends StatefulWidget {
  final Future<XFile?> Function()? pickPhoto;

  const ProfileInfoPage({super.key, this.pickPhoto});

  @override
  State<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  static const _phonePrefixes = <String>['+63', '+1', '+44', '+61', '+81'];
  static const _genderOptions = <String>[
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];

  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();

  String _phonePrefix = '+63';
  String _gender = 'Prefer not to say';
  String _avatarPath = '';
  String _savedAddress = '';

  String _initialName = '';
  String _initialPhone = '';
  String _initialEmail = '';
  String _initialGender = 'Prefer not to say';
  String _initialAvatarPath = '';

  bool _isApplyingProfile = false;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isLoggingOut = false;
  String? _nameError;
  String? _phoneError;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _applyProfile(BlocProvider.of<ProfileCubit>(context).state);
    _nameController.addListener(_updateDirtyState);
    _phoneNumberController.addListener(_updateDirtyState);
    _emailController.addListener(_updateDirtyState);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _applyProfile(ProfileState profile) {
    final phone = _splitPhone(profile.phone);
    _isApplyingProfile = true;
    _nameController.text = profile.name;
    _phonePrefix = phone.prefix;
    _phoneNumberController.text = phone.number;
    _emailController.text = profile.email;
    _gender = _normalizeGender(profile.gender);
    _avatarPath = profile.avatarPath;
    _savedAddress = profile.address;
    _initialName = profile.name.trim();
    _initialPhone = _formatPhone(_phonePrefix, phone.number);
    _initialEmail = profile.email.trim();
    _initialGender = _gender;
    _initialAvatarPath = _avatarPath;
    _isDirty = false;
    _isApplyingProfile = false;
  }

  void _updateDirtyState() {
    if (_isApplyingProfile || !mounted) return;
    final dirty = _draftHasChanges;
    if (_isDirty == dirty) return;
    setState(() => _isDirty = dirty);
  }

  bool get _draftHasChanges =>
      _nameController.text.trim() != _initialName ||
      _currentPhone != _initialPhone ||
      _emailController.text.trim() != _initialEmail ||
      _gender != _initialGender ||
      _avatarPath != _initialAvatarPath;

  String get _currentPhone =>
      _formatPhone(_phonePrefix, _phoneNumberController.text);

  Future<void> _saveProfile() async {
    if (!_isDirty || _isSaving) return;
    _clearErrors();

    final name = _nameController.text.trim();
    final phoneNumber = _phoneNumberController.text.trim();
    final email = _emailController.text.trim();
    var hasError = false;

    if (name.isEmpty) {
      _nameError = 'Name is required';
      hasError = true;
    }
    if (phoneNumber.length < 7) {
      _phoneError = 'Enter a valid mobile number';
      hasError = true;
    }
    if (email.isEmpty) {
      _emailError = 'Email is required';
      hasError = true;
    } else if (!email.contains('@')) {
      _emailError = 'Please enter a valid email';
      hasError = true;
    }
    if (hasError) {
      setState(() {});
      return;
    }

    setState(() => _isSaving = true);
    final didUpdate = await BlocProvider.of<ProfileCubit>(context)
        .updateProfile(
          name: name,
          phone: _currentPhone,
          email: email,
          address: _savedAddress,
          gender: _gender,
          avatarPath: _avatarPath,
        );
    if (!mounted) return;

    setState(() => _isSaving = false);
    if (!didUpdate) {
      CustomToast.show(
        context,
        'We could not update your profile. Please try again.',
        isError: true,
      );
      return;
    }

    _applyProfile(BlocProvider.of<ProfileCubit>(context).state);
    setState(() {});
    CustomToast.show(context, 'Profile updated successfully!');
  }

  void _clearErrors() {
    _nameError = null;
    _phoneError = null;
    _emailError = null;
  }

  Future<void> _pickPhoto() async {
    try {
      final picked = widget.pickPhoto != null
          ? await widget.pickPhoto!()
          : await ImagePicker().pickImage(
              source: ImageSource.gallery,
              maxWidth: 900,
              imageQuality: 86,
            );
      if (!mounted || picked == null) return;
      setState(() {
        _avatarPath = picked.path;
        _isDirty = _draftHasChanges;
      });
    } catch (error, stackTrace) {
      developer.log(
        'Unable to choose passenger profile photo.',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      CustomToast.show(
        context,
        'Unable to choose a photo. Please try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
      listenWhen: (_, current) =>
          current is GuestSession || current is SessionFailure,
      listener: _handleSessionState,
      child: BlocListener<ProfileCubit, ProfileState>(
        listenWhen: (previous, current) =>
            previous.name != current.name ||
            previous.phone != current.phone ||
            previous.email != current.email ||
            previous.address != current.address ||
            previous.gender != current.gender ||
            previous.avatarPath != current.avatarPath,
        listener: (_, state) {
          if (!_isDirty && !_isSaving) _applyProfile(state);
        },
        child: Scaffold(
          backgroundColor: AppTheme.surface,
          appBar: AppBar(
            backgroundColor: AppTheme.surface,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: const Icon(
                LucideIcons.arrow_left,
                color: AppTheme.primaryColor,
                size: 23,
              ),
            ),
            title: const Text(
              'Profile Info',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w900,
                fontSize: 21,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
            actions: [
              if (_isDirty)
                TextButton(
                  key: const ValueKey<String>('passenger-profile-save'),
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                )
              else
                const SizedBox(width: 24),
            ],
          ),
          body: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ProfileAvatarWidget(
                          key: const ValueKey<String>(
                            'passenger-profile-avatar',
                          ),
                          initials: _getInitials(_nameController.text),
                          imagePath: _avatarPath,
                          size: 132,
                          onCameraTap: _pickPhoto,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text(
                          'Add a profile photo',
                          style: TextStyle(
                            color: AppTheme.tertiaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 38),
                      _buildTextField(
                        label: 'Full Name',
                        controller: _nameController,
                        errorText: _nameError,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 24),
                      _buildPhoneField(),
                      const SizedBox(height: 24),
                      _buildTextField(
                        label: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        errorText: _emailError,
                        textInputAction: TextInputAction.done,
                      ),
                      const SizedBox(height: 24),
                      _buildGenderField(),
                      const SizedBox(height: 44),
                      const Divider(height: 1),
                      const SizedBox(height: 28),
                      const Text(
                        'Account actions',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildLogoutButton(context),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? errorText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 9),
        TextField(
          key: ValueKey<String>('passenger-profile-field-$label'),
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          decoration: _fieldDecoration(errorText: errorText),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Mobile Number'),
        const SizedBox(height: 9),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 62,
              width: 94,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppTheme.borderSide),
              ),
              alignment: Alignment.center,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _phonePrefix,
                  isDense: true,
                  icon: const Icon(
                    LucideIcons.chevron_down,
                    size: 18,
                    color: AppTheme.primaryColor,
                  ),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                  items: [
                    for (final prefix in _phonePrefixes)
                      DropdownMenuItem<String>(
                        value: prefix,
                        child: Text(prefix),
                      ),
                  ],
                  onChanged: (prefix) {
                    if (prefix == null || prefix == _phonePrefix) return;
                    setState(() {
                      _phonePrefix = prefix;
                      _isDirty = _draftHasChanges;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const ValueKey<String>('passenger-profile-phone-number'),
                controller: _phoneNumberController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                decoration: _fieldDecoration(
                  hintText: '917 000 0001',
                  errorText: _phoneError,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Gender'),
        const SizedBox(height: 9),
        DropdownButtonFormField<String>(
          key: const ValueKey<String>('passenger-profile-gender'),
          initialValue: _gender,
          isExpanded: true,
          icon: const Icon(
            LucideIcons.chevron_down,
            size: 21,
            color: AppTheme.primaryColor,
          ),
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          decoration: _fieldDecoration(),
          items: [
            for (final gender in _genderOptions)
              DropdownMenuItem<String>(value: gender, child: Text(gender)),
          ],
          onChanged: (gender) {
            if (gender == null) return;
            setState(() {
              _gender = gender;
              _isDirty = _draftHasChanges;
            });
          },
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({String? hintText, String? errorText}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: AppTheme.borderSide),
    );
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      filled: true,
      fillColor: AppTheme.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppTheme.cancel),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppTheme.cancel, width: 1.5),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppTheme.primaryColor.withValues(alpha: 0.48),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.7,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      height: 58,
      width: double.infinity,
      child: OutlinedButton(
        key: const ValueKey<String>('passenger-profile-logout'),
        onPressed: _isLoggingOut ? null : () => _handleLogout(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.cancel,
          side: BorderSide(color: AppTheme.cancel.withValues(alpha: 0.35)),
          backgroundColor: AppTheme.cancel.withValues(alpha: 0.04),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        child: _isLoggingOut
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppTheme.cancel,
                ),
              )
            : const Text('Log Out'),
      ),
    );
  }

  void _handleSessionState(BuildContext context, SessionState state) {
    switch (state) {
      case GuestSession():
        context.goNamed(AuthRoutes.signin);
      case SessionFailure():
        if (_isLoggingOut) {
          setState(() => _isLoggingOut = false);
          CustomToast.show(
            context,
            'Unable to log out. Please try again.',
            isError: true,
          );
        }
      case SessionLoading() || AuthenticatedSession():
        break;
    }
  }

  void _handleLogout(BuildContext context) {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    BlocProvider.of<SessionBloc>(context).add(const SessionLogoutRequested());
  }

  String _getInitials(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'P';
    final parts = trimmedName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  _PhoneParts _splitPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    for (final prefix in _phonePrefixes) {
      final prefixDigits = prefix.substring(1);
      if (digits.startsWith(prefixDigits)) {
        return _PhoneParts(
          prefix: prefix,
          number: digits.substring(prefixDigits.length),
        );
      }
    }
    if (digits.startsWith('0')) {
      return _PhoneParts(prefix: '+63', number: digits.substring(1));
    }
    return _PhoneParts(prefix: '+63', number: digits);
  }

  String _formatPhone(String prefix, String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    return '$prefix$digits';
  }

  String _normalizeGender(String gender) {
    final normalized = gender.trim();
    return _genderOptions.contains(normalized)
        ? normalized
        : 'Prefer not to say';
  }
}

class _PhoneParts {
  final String prefix;
  final String number;

  const _PhoneParts({required this.prefix, required this.number});
}
