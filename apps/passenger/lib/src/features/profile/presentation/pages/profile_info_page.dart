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
import 'package:passenger/src/features/profile/presentation/widgets/profile_info_sections.dart';

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
        child: PopScope(
          canPop: !_isDirty || _isSaving,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            unawaited(_handleUnsavedBackNavigation());
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
            bottomNavigationBar: _isDirty
                ? ProfileInfoSaveBar(
                    isSaving: _isSaving,
                    onDiscard: _discardChanges,
                    onSave: () => unawaited(_saveProfile()),
                  )
                : null,
            body: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth < 360
                      ? AppLayout.pagePadding
                      : AppLayout.pagePaddingWide;
                  return SingleChildScrollView(
                    key: const ValueKey<String>(
                      'passenger-profile-info-scroll',
                    ),
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
                            BlocBuilder<ProfileCubit, ProfileState>(
                              buildWhen: (previous, current) =>
                                  previous.isLoading != current.isLoading ||
                                  previous.errorMessage != current.errorMessage,
                              builder: (context, profileState) => Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (profileState.isLoading) ...[
                                    const LinearProgressIndicator(minHeight: 2),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],
                                  if (!_isSaving && !_isDirty)
                                    if (profileState.errorMessage
                                        case final errorMessage?) ...[
                                      AppErrorBanner(
                                        message: errorMessage,
                                        onRetry: () => unawaited(
                                          BlocProvider.of<ProfileCubit>(context)
                                              .loadProfile(),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                    ],
                                ],
                              ),
                            ),
                            ProfileInfoHero(
                              displayedName: _displayedName,
                              initials: _getInitials(_displayedName),
                              avatarPath: _avatarPath,
                              avatarData: _avatarData,
                              isSaving: _isSaving,
                              onPickPhoto: () => unawaited(_pickPhoto()),
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                            const ProfileInfoSectionHeader(title: 'Profile'),
                            const SizedBox(height: AppSpacing.sm),
                            ProfileInfoEditableCard(
                              nameController: _nameController,
                              nameError: _nameError,
                              gender: _gender,
                              genderOptions: _genderOptions,
                              onGenderChanged: (gender) {
                                setState(() {
                                  _gender = gender;
                                  _isDirty = _draftHasChanges;
                                });
                              },
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            const ProfileInfoSectionHeader(
                              title: 'Contact',
                              trailing: ProfileInfoVerifiedTag(),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            ProfileInfoContactCard(
                              phonePrefix: _phonePrefix,
                              phoneNumberController: _phoneNumberController,
                              emailController: _emailController,
                            ),
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
      ),
    );
  }

  Future<void> _handleUnsavedBackNavigation() async {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Discard unsaved changes?',
                  textAlign: TextAlign.center,
                  style: textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your profile edits have not been saved yet.',
                  textAlign: TextAlign.center,
                  style: textStyles.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
                  height: AppSize.controlHeight,
                  child: FilledButton(
                    key: const ValueKey<String>(
                      'passenger-profile-discard-confirm',
                    ),
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      elevation: 0,
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: const Text('Discard changes'),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  height: AppSize.controlHeight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(color: colorScheme.outlineVariant),
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                    child: const Text('Keep editing'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (discard == true && mounted && context.mounted) {
      setState(() => _isDirty = false);
      Navigator.of(context).pop();
    }
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
