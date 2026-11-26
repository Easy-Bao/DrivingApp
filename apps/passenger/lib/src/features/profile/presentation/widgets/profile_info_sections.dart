import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/profile/presentation/widgets/profile_avatar.dart';

class ProfileInfoHero extends StatelessWidget {
  const ProfileInfoHero({
    super.key,
    required this.displayedName,
    required this.initials,
    required this.avatarPath,
    required this.avatarData,
    required this.isSaving,
    required this.onPickPhoto,
  });

  final String displayedName;
  final String initials;
  final String avatarPath;
  final String avatarData;
  final bool isSaving;
  final VoidCallback onPickPhoto;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final displayName = displayedName.isEmpty || displayedName.contains('@')
        ? 'Your profile'
        : displayedName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ProfileAvatar(
          key: const ValueKey<String>('passenger-profile-avatar'),
          initials: initials,
          imagePath: avatarPath,
          imageData: avatarData,
          size: 88,
          onCameraTap: onPickPhoto,
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
          onPressed: isSaving ? null : onPickPhoto,
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
}

class ProfileInfoSectionHeader extends StatelessWidget {
  const ProfileInfoSectionHeader({
    super.key,
    required this.title,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
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
          if (trailing case final trailingWidget?) ...[
            const SizedBox(width: AppSpacing.sm),
            trailingWidget,
          ],
        ],
      ),
    );
  }
}

class ProfileInfoVerifiedTag extends StatelessWidget {
  const ProfileInfoVerifiedTag({super.key});

  @override
  Widget build(BuildContext context) {
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
}

class ProfileInfoEditableCard extends StatelessWidget {
  const ProfileInfoEditableCard({
    super.key,
    required this.nameController,
    required this.nameError,
    required this.gender,
    required this.genderOptions,
    required this.onGenderChanged,
  });

  final TextEditingController nameController;
  final String? nameError;
  final String gender;
  final List<String> genderOptions;
  final ValueChanged<String> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return AppSurfaceCard(
      key: const ValueKey<String>('passenger-profile-editable-card'),
      color: colorScheme.surfaceContainerLowest,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileFieldRow(
            label: 'Full name',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  key: const ValueKey<String>(
                    'passenger-profile-field-Full Name',
                  ),
                  controller: nameController,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  style: context.textStyles.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  decoration: _bareFieldDecoration(
                    context,
                    hintText: 'Enter your name',
                  ),
                ),
                if (nameError case final error?) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      error,
                      style: context.textStyles.labelMedium?.copyWith(
                        color: colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const _ProfileRowDivider(),
          _ProfileFieldRow(
            label: 'Gender',
            child: AppSelectField<String>(
              key: const ValueKey<String>('passenger-profile-gender'),
              value: gender,
              menuTitle: 'Gender',
              style: context.textStyles.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              decoration: _bareFieldDecoration(
                context,
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
                for (final option in genderOptions)
                  AppSelectOption<String>(value: option, label: option),
              ],
              onChanged: (selected) {
                if (selected != null) {
                  onGenderChanged(selected);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileInfoContactCard extends StatelessWidget {
  const ProfileInfoContactCard({
    super.key,
    required this.phonePrefix,
    required this.phoneNumberController,
    required this.emailController,
  });

  final String phonePrefix;
  final TextEditingController phoneNumberController;
  final TextEditingController emailController;

  @override
  Widget build(BuildContext context) {
    final readOnlyColor = context.colorScheme.onSurfaceVariant;
    return AppSurfaceCard(
      key: const ValueKey<String>('passenger-profile-contact-card'),
      color: context.colorScheme.surfaceContainerLow,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ProfileFieldRow(
            label: 'Mobile number',
            child: Row(
              children: [
                Text(
                  phonePrefix,
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
                    key: const ValueKey<String>(
                      'passenger-profile-phone-number',
                    ),
                    controller: phoneNumberController,
                    readOnly: true,
                    showCursor: false,
                    keyboardType: TextInputType.phone,
                    style: context.textStyles.bodyLarge?.tabular.copyWith(
                      fontWeight: FontWeight.w500,
                      color: readOnlyColor,
                    ),
                    decoration: _bareFieldDecoration(
                      context,
                      hintText: '917 000 0001',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _ProfileRowDivider(),
          _ProfileFieldRow(
            label: 'Email',
            child: TextField(
              key: const ValueKey<String>('passenger-profile-field-Email'),
              controller: emailController,
              readOnly: true,
              showCursor: false,
              keyboardType: TextInputType.emailAddress,
              textCapitalization: TextCapitalization.none,
              style: context.textStyles.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: readOnlyColor,
              ),
              decoration: _bareFieldDecoration(
                context,
                hintText: 'name@example.com',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileInfoSaveBar extends StatelessWidget {
  const ProfileInfoSaveBar({
    super.key,
    required this.isSaving,
    required this.onDiscard,
    required this.onSave,
  });

  final bool isSaving;
  final VoidCallback onDiscard;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
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
                onPressed: isSaving ? null : onDiscard,
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
                onPressed: isSaving ? null : onSave,
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
                child: isSaving
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
}

class _ProfileRowDivider extends StatelessWidget {
  const _ProfileRowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
      color: context.colorScheme.outlineVariant.withValues(alpha: 0.7),
    );
  }
}

class _ProfileFieldRow extends StatelessWidget {
  const _ProfileFieldRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.textStyles.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

InputDecoration _bareFieldDecoration(
  BuildContext context, {
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
