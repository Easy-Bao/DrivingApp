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
import 'package:passenger/src/features/profile/domain/repositories/profile_repository.dart';
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
  String _displayedName = '';

  bool _isApplyingProfile = false;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isPickingPhoto = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _applyProfile(BlocProvider.of<ProfileCubit>(context).state);
    _nameController.addListener(_onNameChanged);
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
    _displayedName = name;
    _nameError = null;
    _isDirty = false;
    _isApplyingProfile = false;
  }

  void _onNameChanged() {
    if (_isApplyingProfile || !mounted) return;
    final trimmed = _nameController.text.trim();
    final dirty = _draftHasChanges;
    final clearError = _nameError != null && trimmed.isNotEmpty;
    if (_isDirty == dirty && !clearError && _displayedName == trimmed) return;
    setState(() {
      _displayedName = trimmed;
      _isDirty = dirty;
      if (clearError) {
        _nameError = null;
      }
    });
  }

  bool get _draftHasChanges =>
      _nameController.text.trim() != _initialName ||
      _gender != _initialGender ||
      _avatarPath != _initialAvatarPath;

  void _discardChanges() {
    if (!_isDirty || _isSaving) return;
    setState(() {
      _isApplyingProfile = true;
      _nameController.text = _initialName;
      _gender = _initialGender;
      _avatarPath = _initialAvatarPath;
      _displayedName = _initialName;
      _nameError = null;
      _isDirty = false;
      _isApplyingProfile = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_isDirty || _isSaving) return;
    _nameError = null;

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
    AppSnackBar.show(context, 'Profile updated.');
  }

  Future<void> _pickPhoto() async {
    if (_isPickingPhoto || _isSaving) return;
    _isPickingPhoto = true;
    try {
      final pickPhoto = widget.pickPhoto;
      final picked = pickPhoto != null
          ? await pickPhoto()
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
          if (await file.exists()) {
            fileSize = await file.length();
          }
        }
        if (fileSize == null && (kIsWeb || picked.path.isEmpty)) {
          fileSize = await picked.length();
        }
        if (fileSize != null && fileSize > ProfileRepository.maxAvatarBytes) {
          if (!mounted) return;
          AppSnackBar.show(
            context,
            'Selected photo exceeds 2 MB. Choose a smaller image.',
            isError: true,
          );
          return;
        }
      } catch (_) {
        // Proceed when file size cannot be resolved on the host platform.
      }
      if (!mounted) return;
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
    } finally {
      _isPickingPhoto = false;
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
          if (!_isDirty && !_isSaving) {
            _applyProfile(state);
            if (mounted) setState(() {});
          }
        },
        child: Scaffold(
          backgroundColor: context.canvasColor,
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
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: colorScheme.onSurface,
              ),
            ),
            centerTitle: true,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
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
                    AppSpacing.xxl,
                    horizontalPadding,
                    AppSpacing.xxxl,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildProfileHero(context),
                          const SizedBox(height: AppSpacing.xxxl),
                          _buildSectionHeader(context, title: 'Profile'),
                          const SizedBox(height: AppSpacing.sm),
                          _buildProfileCard(context),
                          const SizedBox(height: AppSpacing.xxl),
                          _buildSectionHeader(
                            context,
                            title: 'Contact',
                            trailing: _buildVerifiedTag(context),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _buildContactCard(context),
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                            ),
                            child: Text(
                              'Email and phone changes require verification.',
                              style: context.textStyles.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
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

  Widget _buildProfileHero(BuildContext context) {
    final colorScheme = context.colorScheme;
    final rawName = _displayedName;
    final displayName = rawName.isEmpty || rawName.contains('@')
        ? 'Your profile'
        : rawName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ProfileAvatar(
          key: const ValueKey<String>('passenger-profile-avatar'),
          initials: _getInitials(rawName),
          imagePath: _avatarPath,
          imageData: _avatarData,
          size: 88,
          onCameraTap: _pickPhoto,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: context.textStyles.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton(
          key: const ValueKey<String>('passenger-profile-change-photo'),
          onPressed: _isSaving ? null : _pickPhoto,
          style:
              OutlinedButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerLowest,
                foregroundColor: colorScheme.onSurface,
                side: BorderSide(color: colorScheme.outlineVariant),
                enableFeedback: false,
                splashFactory: NoSplash.splashFactory,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 8,
                ),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.padded,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                textStyle: context.textStyles.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.focused)) {
                    return colorScheme.primary.withValues(alpha: 0.12);
                  }
                  return Colors.transparent;
                }),
              ),
          child: const Text('Change photo'),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title.toUpperCase(),
                style: context.textStyles.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.9,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.sm),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildVerifiedTag(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: Icon(
            LucideIcons.lock,
            size: 11,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Verified',
          style: context.textStyles.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return AppSurfaceCard(
      key: const ValueKey<String>('passenger-profile-editable-card'),
      color: context.colorScheme.surfaceContainerLowest,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFullNameRow(context),
          _buildRowDivider(context),
          _buildGenderRow(context),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return AppSurfaceCard(
      key: const ValueKey<String>('passenger-profile-contact-card'),
      color: context.colorScheme.surfaceContainerLow,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildPhoneRow(context),
          _buildRowDivider(context),
          _buildEmailRow(context),
        ],
      ),
    );
  }

  Widget _buildRowDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
      color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
    );
  }

  Widget _buildFieldRow(
    BuildContext context, {
    required String label,
    required Widget child,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.textStyles.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: AppSpacing.sm),
                trailing,
              ],
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
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
      hintStyle: context.textStyles.bodyLarge?.copyWith(
        color: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: suffixIconConstraints,
    );
  }

  Widget _buildFullNameRow(BuildContext context) {
    final colorScheme = context.colorScheme;
    return _buildFieldRow(
      context,
      label: 'Full name',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey<String>('passenger-profile-field-Full Name'),
            controller: _nameController,
            textInputAction: TextInputAction.done,
            textCapitalization: TextCapitalization.words,
            style: context.textStyles.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            decoration: _bareFieldDecoration(hintText: 'Enter your name'),
          ),
          if (_nameError case final nameError?) ...[
            const SizedBox(height: AppSpacing.xs),
            Semantics(
              liveRegion: true,
              child: Text(
                nameError,
                style: context.textStyles.labelMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenderRow(BuildContext context) {
    final colorScheme = context.colorScheme;
    return _buildFieldRow(
      context,
      label: 'Gender',
      child: AppSelectField<String>(
        key: const ValueKey<String>('passenger-profile-gender'),
        value: _gender,
        menuTitle: 'Gender',
        style: context.textStyles.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        decoration: _bareFieldDecoration(
          suffixIcon: Icon(
            LucideIcons.chevron_down,
            size: 18,
            color: colorScheme.onSurfaceVariant,
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

  Widget _buildPhoneRow(BuildContext context) {
    final readOnlyColor = context.colorScheme.onSurfaceVariant;
    return _buildFieldRow(
      context,
      label: 'Mobile number',
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
            height: 16,
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

  Widget _buildEmailRow(BuildContext context) {
    return _buildFieldRow(
      context,
      label: 'Email',
      child: TextField(
        key: const ValueKey<String>('passenger-profile-field-Email'),
        controller: _emailController,
        readOnly: true,
        showCursor: false,
        keyboardType: TextInputType.emailAddress,
        textCapitalization: TextCapitalization.none,
        style: context.textStyles.bodyLarge?.copyWith(
          fontWeight: FontWeight.w500,
          color: context.colorScheme.onSurfaceVariant,
        ),
        decoration: _bareFieldDecoration(hintText: 'name@example.com'),
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
              final compactActions =
                  constraints.maxWidth < 320 ||
                  MediaQuery.textScalerOf(context).scale(14) > 21;

              final discardButton = OutlinedButton(
                key: const ValueKey<String>('passenger-profile-discard'),
                onPressed: _isSaving ? null : _discardChanges,
                style:
                    OutlinedButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerLowest,
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: colorScheme.outlineVariant),
                      elevation: 0,
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                      minimumSize: const Size.fromHeight(AppSize.controlHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      textStyle: context.textStyles.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.focused)) {
                          return colorScheme.primary.withValues(alpha: 0.12);
                        }
                        return Colors.transparent;
                      }),
                    ),
                child: const Text('Discard'),
              );

              final saveButton = FilledButton(
                key: const ValueKey<String>('passenger-profile-save'),
                onPressed: _isSaving ? null : _saveProfile,
                style:
                    FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      elevation: 0,
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                      minimumSize: const Size.fromHeight(AppSize.controlHeight),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      textStyle: context.textStyles.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.focused)) {
                          return colorScheme.onPrimary.withValues(alpha: 0.16);
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
                    : const Text('Save changes'),
              );

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
                      child: compactActions
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                saveButton,
                                const SizedBox(height: AppSpacing.sm),
                                discardButton,
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: discardButton),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(flex: 2, child: saveButton),
                              ],
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
