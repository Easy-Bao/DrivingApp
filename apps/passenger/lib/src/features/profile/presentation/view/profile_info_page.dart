import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:image_picker/image_picker.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile/profile_cubit.dart';
import 'package:passenger/src/features/profile/presentation/widgets/profile_avatar.dart';

class ProfileInfoPage extends StatefulWidget {
  const ProfileInfoPage({super.key, this.pickPhoto});

  final Future<XFile?> Function()? pickPhoto;

  @override
  State<ProfileInfoPage> createState() => _ProfileInfoPageState();
}

class _ProfileInfoPageState extends State<ProfileInfoPage> {
  static const _phonePrefix = '+63';
  static const _genderOptions = <String>[
    'Female',
    'Male',
    'Non-binary',
    'Prefer not to say',
  ];

  final _nameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();

  String _gender = 'Prefer not to say';
  String _avatarPath = '';
  String _avatarData = '';
  String _savedAddress = '';

  String _initialName = '';
  String _initialGender = 'Prefer not to say';
  String _initialAvatarPath = '';

  bool _isApplyingProfile = false;
  bool _isDirty = false;
  bool _isSaving = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _applyProfile(BlocProvider.of<ProfileCubit>(context).state);
    _nameController.addListener(_updateDirtyState);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _applyProfile(ProfileState profile) {
    _isApplyingProfile = true;
    var name = profile.name.trim();
    final email = profile.email.trim();

    if (name.isEmpty ||
        (email.isNotEmpty && name.toLowerCase() == email.toLowerCase()) ||
        name.contains('@')) {
      final session = BlocProvider.of<SessionBloc>(context).state;
      if (session is AuthenticatedSession &&
          session.passengerName.trim().isNotEmpty &&
          !session.passengerName.trim().contains('@')) {
        name = session.passengerName.trim();
      } else if (name.contains('@')) {
        name = '';
      }
    }

    _nameController.text = name;
    _phoneNumberController.text = _localPhoneNumber(profile.phone);
    _emailController.text = email;
    _gender = _normalizeGender(profile.gender);
    _avatarPath = profile.avatarPath;
    _avatarData = profile.avatarData;
    _savedAddress = profile.address;
    _initialName = name;
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
      _gender != _initialGender ||
      _avatarPath != _initialAvatarPath;

  Future<void> _saveProfile() async {
    if (!_isDirty || _isSaving) return;
    _clearErrors();

    final name = _nameController.text.trim();
    var hasError = false;

    if (name.isEmpty) {
      _nameError = 'Enter your name.';
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
          address: _savedAddress,
          gender: _gender,
          avatarPath: _avatarPath,
        );
    if (!mounted) return;

    setState(() => _isSaving = false);
    if (!didUpdate) {
      CustomToast.show(
        context,
        "Couldn't update your profile. Try again.",
        isError: true,
      );
      return;
    }

    _applyProfile(BlocProvider.of<ProfileCubit>(context).state);
    setState(() {});
    CustomToast.show(context, 'Profile updated.');
  }

  void _clearErrors() {
    _nameError = null;
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
      try {
        int? fileSize;
        if (!kIsWeb && picked.path.isNotEmpty) {
          final file = File(picked.path);
          if (file.existsSync()) {
            fileSize = file.lengthSync();
          }
        }
        if (fileSize == null && (kIsWeb || picked.path.isEmpty)) {
          fileSize = await picked.length();
        }
        if (fileSize != null && fileSize > 5 * 1024 * 1024) {
          if (!mounted) return;
          CustomToast.show(
            context,
            'Selected photo exceeds 5MB limit. Please choose a smaller image.',
            isError: true,
          );
          return;
        }
      } catch (_) {
        // If file size check cannot be completed, allow proceeding.
      }
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
            previous.avatarPath != current.avatarPath ||
            previous.avatarUrl != current.avatarUrl ||
            previous.avatarData != current.avatarData,
        listener: (_, state) {
          if (!_isDirty && !_isSaving) _applyProfile(state);
        },
        child: Scaffold(
          backgroundColor: context.canvasColor,
          appBar: AppBar(
            backgroundColor: context.canvasColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              icon: Icon(
                LucideIcons.arrow_left,
                color: context.colorScheme.onSurface,
                size: 22,
              ),
            ),
            title: Text(
              'Profile Info',
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            centerTitle: true,
          ),
          bottomNavigationBar: _buildBottomBar(context),
          body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 360
                    ? EasyRideLayout.pagePadding
                    : EasyRideLayout.pagePaddingWide;
                return SingleChildScrollView(
                  key: const ValueKey<String>('passenger-profile-info-scroll'),
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    12,
                    horizontalPadding,
                    24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: EasyRideSpacing.xxl * 1.5),
                          _buildDetailsSection(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildBottomBar(BuildContext context) {
    if (!_isDirty) return null;
    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = constraints.maxWidth < 360
              ? EasyRideLayout.pagePadding
              : EasyRideLayout.pagePaddingWide;
          return Container(
            color: context.canvasColor,
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              12,
              horizontalPadding,
              16,
            ),
            child: Center(
              heightFactor: 1,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: SizedBox(
                  width: double.infinity,
                  height: EasyRideSize.controlHeight,
                  child: FilledButton(
                    key: const ValueKey<String>('passenger-profile-save'),
                    onPressed: _isSaving ? null : _saveProfile,
                    style: FilledButton.styleFrom(
                      backgroundColor: context.colorScheme.primary,
                      foregroundColor: context.colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: context.colorScheme.onPrimary,
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    final rawName = _nameController.text.trim();
    final displayName = rawName.isEmpty || rawName.contains('@')
        ? 'Your profile'
        : rawName;
    final displayEmail = _emailController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ProfileAvatar(
            key: const ValueKey<String>('passenger-profile-avatar'),
            initials: _getInitials(_nameController.text),
            imagePath: _avatarPath,
            imageData: _avatarData,
            size: 112,
            onCameraTap: _pickPhoto,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: context.textStyles.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          displayEmail.isEmpty
              ? 'Add an email for ride updates.'
              : displayEmail,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall,
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return EasyRideSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFullNameTile(),
          _buildDivider(),
          _buildPhoneTile(),
          _buildDivider(),
          _buildEmailTile(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              EasyRideSpacing.lg,
              0,
              EasyRideSpacing.lg,
              EasyRideSpacing.md,
            ),
            child: Text(
              'Email and phone changes require verification.',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          _buildDivider(),
          _buildGenderTile(),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 16,
      endIndent: 16,
      color: context.colorScheme.outlineVariant.withValues(alpha: 0.65),
    );
  }

  Widget _buildFullNameTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EasyRideSpacing.lg,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.user_round,
            size: 20,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFieldLabel('Full Name'),
                const SizedBox(height: 4),
                TextField(
                  key: const ValueKey<String>(
                    'passenger-profile-field-Full Name',
                  ),
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  style: context.textStyles.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'Enter your name',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (_nameError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _nameError!,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EasyRideSpacing.lg,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.phone,
            size: 20,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFieldLabel('Mobile Number'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _phonePrefix,
                      style: context.textStyles.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colorScheme.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 1,
                      height: 16,
                      color: context.colorScheme.outlineVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        key: const ValueKey<String>(
                          'passenger-profile-phone-number',
                        ),
                        controller: _phoneNumberController,
                        readOnly: true,
                        showCursor: false,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        style: context.textStyles.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: '917 000 0001',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: context.colorScheme.onSurface.withValues(
                              alpha: 0.38,
                            ),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EasyRideSpacing.lg,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.mail,
            size: 20,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFieldLabel('Email'),
                const SizedBox(height: 4),
                TextField(
                  key: const ValueKey<String>('passenger-profile-field-Email'),
                  controller: _emailController,
                  readOnly: true,
                  showCursor: false,
                  keyboardType: TextInputType.emailAddress,
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.done,
                  style: context.textStyles.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    hintText: 'name@example.com',
                    hintStyle: TextStyle(
                      fontSize: 15,
                      color: context.colorScheme.onSurface.withValues(
                        alpha: 0.38,
                      ),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenderTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EasyRideSpacing.lg,
        vertical: 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.venus_and_mars,
            size: 20,
            color: context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFieldLabel('Gender'),
                const SizedBox(height: 4),
                EasyRideSelectField<String>(
                  key: const ValueKey<String>('passenger-profile-gender'),
                  value: _gender,
                  menuTitle: 'Gender',
                  style: context.textStyles.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    suffixIcon: Icon(
                      LucideIcons.chevron_down,
                      size: 18,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                  ),
                  options: [
                    for (final gender in _genderOptions)
                      EasyRideSelectOption<String>(
                        value: gender,
                        label: gender,
                      ),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: context.colorScheme.onSurfaceVariant,
      ),
    );
  }

  void _handleSessionState(BuildContext context, SessionState state) {
    switch (state) {
      case GuestSession() || SessionFailure():
        context.goNamed(AuthRoutes.signin);
      case SessionLoading() || AuthenticatedSession():
        break;
    }
  }

  String _getInitials(String name) {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || trimmedName.contains('@')) return 'P';
    final parts = trimmedName.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  String _localPhoneNumber(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('63')) {
      return digits.substring(2);
    }
    if (digits.startsWith('0')) {
      return digits.substring(1);
    }
    return digits;
  }

  String _normalizeGender(String gender) {
    final normalized = gender.trim();
    return _genderOptions.contains(normalized)
        ? normalized
        : 'Prefer not to say';
  }
}
