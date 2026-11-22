import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/profile/presentation/bloc/profile_cubit.dart';
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
    if (_isDirty == dirty && _nameError == null) return;
    setState(() {
      _isDirty = dirty;
      if (_nameError != null && _nameController.text.trim().isNotEmpty) {
        _nameError = null;
      }
    });
  }

  bool get _draftHasChanges =>
      _nameController.text.trim() != _initialName ||
      _gender != _initialGender ||
      _avatarPath != _initialAvatarPath;

  Future<void> _saveProfile() async {
    if (!_isDirty || _isSaving) return;
    _clearErrors();

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Enter your name.');
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
      final state = BlocProvider.of<ProfileCubit>(context).state;
      AppSnackBar.show(
        context,
        state.errorMessage ?? "Couldn't update your profile. Try again.",
        isError: true,
      );
      return;
    }

    _applyProfile(BlocProvider.of<ProfileCubit>(context).state);
    setState(() {});
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
          AppSnackBar.show(
            context,
            'Selected photo exceeds 5MB. Choose a smaller image.',
            isError: true,
          );
          return;
        }
      } catch (_) {
        // Proceed when file size cannot be resolved on the host platform.
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
      AppSnackBar.show(
        context,
        'Unable to choose a photo. Try again.',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

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
          appBar: AppBar(
            backgroundColor: context.canvasColor,
            scrolledUnderElevation: 0,
            leading: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              style:
                  IconButton.styleFrom(
                    enableFeedback: false,
                    splashFactory: NoSplash.splashFactory,
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.focused)) {
                        return colorScheme.primary.withValues(alpha: 0.12);
                      }
                      return Colors.transparent;
                    }),
                  ),
              icon: Icon(
                LucideIcons.arrow_left,
                color: colorScheme.onSurface,
                size: 20,
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
                    ? AppLayout.pagePadding
                    : AppLayout.pagePaddingWide;
                return SingleChildScrollView(
                  key: const ValueKey<String>('passenger-profile-info-scroll'),
                  physics: const ClampingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.lg,
                    horizontalPadding,
                    AppSpacing.xxxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: AppSpacing.xxxl),
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
    final colorScheme = context.colorScheme;
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 200);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Opacity(
        opacity: progress.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - progress)),
          child: child,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360
                  ? AppLayout.pagePadding
                  : AppLayout.pagePaddingWide;
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: context.canvasColor,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    AppSpacing.md,
                    horizontalPadding,
                    AppSpacing.lg,
                  ),
                  child: Center(
                    heightFactor: 1,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: SizedBox(
                        width: double.infinity,
                        height: AppSize.controlHeight,
                        child: FilledButton(
                          key: const ValueKey<String>('passenger-profile-save'),
                          onPressed: _isSaving ? null : _saveProfile,
                          style:
                              FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                elevation: 0,
                                enableFeedback: false,
                                splashFactory: NoSplash.splashFactory,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                              ).copyWith(
                                overlayColor: WidgetStateProperty.resolveWith((
                                  states,
                                ) {
                                  if (states.contains(WidgetState.focused)) {
                                    return colorScheme.onPrimary.withValues(
                                      alpha: 0.16,
                                    );
                                  }
                                  return Colors.transparent;
                                }),
                              ),
                          child: _isSaving
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: colorScheme.onPrimary,
                                  ),
                                )
                              : const Text('Save'),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
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
            size: 96,
            onCameraTap: _pickPhoto,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: context.textStyles.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          displayEmail.isEmpty
              ? 'Add an email for ride updates.'
              : displayEmail,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return AppSurfaceCard(
      color: context.colorScheme.surfaceContainerLowest,
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
              52,
              0,
              AppSpacing.lg,
              AppSpacing.md,
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
      indent: 52,
      endIndent: AppSpacing.lg,
      color: context.colorScheme.outlineVariant.withValues(alpha: 0.65),
    );
  }

  InputDecoration _bareFieldDecoration({
    String? hintText,
    Widget? suffixIcon,
    BoxConstraints? suffixIconConstraints,
  }) {
    return InputDecoration(
      isDense: true,
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      hintText: hintText,
      hintStyle: context.textStyles.bodyMedium?.copyWith(
        color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: suffixIconConstraints,
    );
  }

  Widget _buildFieldRow({
    required IconData icon,
    required String label,
    required Widget child,
    bool isReadOnly = false,
  }) {
    final colorScheme = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 15,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ExcludeSemantics(
              child: Icon(
                icon,
                size: 18,
                color: isReadOnly
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.72)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(child: _buildFieldLabel(label)),
                    if (isReadOnly) ...[
                      const SizedBox(width: 6),
                      ExcludeSemantics(
                        child: Icon(
                          LucideIcons.lock,
                          size: 11,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.72,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullNameTile() {
    return _buildFieldRow(
      icon: LucideIcons.user_round,
      label: 'Full Name',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey<String>('passenger-profile-field-Full Name'),
            controller: _nameController,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            style: context.textStyles.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colorScheme.onSurface,
            ),
            decoration: _bareFieldDecoration(hintText: 'Enter your name'),
          ),
          if (_nameError != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              liveRegion: true,
              child: Text(
                _nameError!,
                style: context.textStyles.labelMedium?.copyWith(
                  color: context.colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhoneTile() {
    final readOnlyColor = context.colorScheme.onSurfaceVariant;
    return _buildFieldRow(
      icon: LucideIcons.phone,
      label: 'Mobile Number',
      isReadOnly: true,
      child: Row(
        children: [
          Text(
            _phonePrefix,
            style: context.textStyles.bodyLarge?.tabular.copyWith(
              fontWeight: FontWeight.w600,
              color: readOnlyColor,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 1,
            height: 15,
            color: context.colorScheme.outlineVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              key: const ValueKey<String>('passenger-profile-phone-number'),
              controller: _phoneNumberController,
              readOnly: true,
              showCursor: false,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              style: context.textStyles.bodyLarge?.tabular.copyWith(
                fontWeight: FontWeight.w500,
                color: readOnlyColor,
              ),
              decoration: _bareFieldDecoration(hintText: '917 000 0001'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailTile() {
    return _buildFieldRow(
      icon: LucideIcons.mail,
      label: 'Email',
      isReadOnly: true,
      child: TextField(
        key: const ValueKey<String>('passenger-profile-field-Email'),
        controller: _emailController,
        readOnly: true,
        showCursor: false,
        keyboardType: TextInputType.emailAddress,
        textCapitalization: TextCapitalization.none,
        textInputAction: TextInputAction.done,
        style: context.textStyles.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: context.colorScheme.onSurfaceVariant,
        ),
        decoration: _bareFieldDecoration(hintText: 'name@example.com'),
      ),
    );
  }

  Widget _buildGenderTile() {
    return _buildFieldRow(
      icon: LucideIcons.venus_and_mars,
      label: 'Gender',
      child: AppSelectField<String>(
        key: const ValueKey<String>('passenger-profile-gender'),
        value: _gender,
        menuTitle: 'Gender',
        style: context.textStyles.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: context.colorScheme.onSurface,
        ),
        decoration: _bareFieldDecoration(
          suffixIcon: Icon(
            LucideIcons.chevron_down,
            size: 17,
            color: context.colorScheme.onSurfaceVariant,
          ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 20,
            minHeight: 20,
          ),
        ),
        options: [
          for (final gender in _genderOptions)
            AppSelectOption<String>(value: gender, label: gender),
        ],
        onChanged: (gender) {
          if (gender == null) return;
          setState(() {
            _gender = gender;
            _isDirty = _draftHasChanges;
          });
        },
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: context.textStyles.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.85,
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
