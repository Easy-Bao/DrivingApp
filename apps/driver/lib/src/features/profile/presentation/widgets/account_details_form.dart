import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/profile/domain/entities/account_snapshot.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';

enum AccountDetailsSection { personal, vehicle }

class const AccountDetailsForm({super.key, required this.section, this.onBack})
    extends StatefulWidget {
  final AccountDetailsSection section;
  final VoidCallback? onBack;

  @override
  State<AccountDetailsForm> createState() => _AccountDetailsFormState();
}

class _AccountDetailsFormState extends State<AccountDetailsForm> {
  final _vehicleTypeController = TextEditingController();
  final _plateNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _applyAccount(BlocProvider.of<AccountCubit>(context).state.account);
  }

  List<TextEditingController> get _controllers => [
    _vehicleTypeController,
    _plateNumberController,
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _applyAccount(AccountSnapshot account) {
    _vehicleTypeController.text = account.vehicleType;
    _plateNumberController.text = account.plateNumber;
  }

  String get _pageTitle => switch (widget.section) {
    AccountDetailsSection.personal => 'Personal details',
    AccountDetailsSection.vehicle => 'Vehicle Information',
  };

  Future<void> _submitSave() async {
    final cubit = BlocProvider.of<AccountCubit>(context);
    final currentAccount = cubit.state.account;
    final success = await cubit.updateAccount(
      name: currentAccount.name,
      vehicleType: _vehicleTypeController.text.trim(),
      plateNumber: _plateNumberController.text.trim(),
    );
    if (!mounted || !context.mounted) return;
    if (success) {
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AccountCubit, AccountState>(
      listenWhen: (previous, current) => previous.account != current.account,
      listener: (_, state) {
        _applyAccount(state.account);
      },
      builder: (context, state) {
        final isPersonal = widget.section == AccountDetailsSection.personal;
        return AppSecondaryPage(
          title: _pageTitle,
          onBack: widget.onBack ?? () => context.pop(),
          maxWidth: 560,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 360
                  ? AppLayout.pagePadding
                  : AppLayout.pagePaddingWide;
              return ListView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.xl,
                  horizontalPadding,
                  48,
                ),
                children: [
                  _buildHeader(state.account),
                  const SizedBox(height: AppSpacing.xxxl),
                  if (isPersonal)
                    ..._buildPersonalFields(state)
                  else
                    ..._buildVehicleFields(state),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHeader(AccountSnapshot account) {
    final isPersonal = widget.section == AccountDetailsSection.personal;
    final displayName = account.name.trim();
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Column(
      children: [
        ExcludeSemantics(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            alignment: Alignment.center,
            child: isPersonal
                ? Text(
                    _initials(displayName),
                    style: textStyles.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  )
                : Icon(
                    LucideIcons.car_front,
                    size: 28,
                    color: colorScheme.onSurface,
                  ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          isPersonal
              ? 'Your contact details'
              : 'Your registered service vehicle',
          textAlign: TextAlign.center,
          style: textStyles.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPersonalFields(AccountState state) {
    final account = state.account;
    final colorScheme = context.colorScheme;
    final hairline = Divider(
      height: 1,
      thickness: 1,
      color: colorScheme.outlineVariant.withValues(alpha: 0.7),
    );
    final insetHairline = Divider(
      height: 1,
      thickness: 1,
      indent: 34,
      color: colorScheme.outlineVariant.withValues(alpha: 0.65),
    );

    return [
      if (state.isLoading) ...[
        const LinearProgressIndicator(minHeight: 2),
        const SizedBox(height: AppSpacing.lg),
      ],
      if (state.errorMessage != null) ...[
        AppErrorBanner(
          message: state.errorMessage!,
          onRetry: () => BlocProvider.of<AccountCubit>(context).load(),
          onDismiss: () =>
              BlocProvider.of<AccountCubit>(context).dismissError(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      hairline,
      _buildContactDetail(
        icon: LucideIcons.user_round,
        label: 'Full name',
        value: account.name,
      ),
      insetHairline,
      _buildContactDetail(
        icon: LucideIcons.phone,
        label: 'Mobile number',
        value: account.phone,
        isVerifiedLocked: true,
        useTabular: true,
      ),
      insetHairline,
      _buildContactDetail(
        icon: LucideIcons.mail,
        label: 'Email',
        value: account.email,
        isVerifiedLocked: true,
      ),
      hairline,
      const SizedBox(height: AppSpacing.xl),
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.75),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: ExcludeSemantics(
                child: Icon(
                  LucideIcons.lock_keyhole,
                  size: 15,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 2),
            Expanded(
              child: Text(
                'Phone number and email are verified account identifiers and can’t be edited here.',
                style: context.textStyles.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildContactDetail({
    required IconData icon,
    required String label,
    required String value,
    bool isVerifiedLocked = false,
    bool useTabular = false,
  }) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final isEmpty = value.trim().isEmpty;
    final baseValueStyle =
        (useTabular ? textStyles.bodyLarge?.tabular : textStyles.bodyLarge)
            ?.copyWith(
              fontWeight: isVerifiedLocked || isEmpty
                  ? FontWeight.w500
                  : FontWeight.w600,
              color: isVerifiedLocked || isEmpty
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface,
            );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: ExcludeSemantics(
              child: Icon(
                icon,
                size: 18,
                color: isVerifiedLocked
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.72)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: textStyles.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isVerifiedLocked) ...[
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
                Text(isEmpty ? 'Not provided' : value, style: baseValueStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVehicleFields(AccountState state) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return [
      DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileTextField(
              icon: LucideIcons.car_front,
              label: 'Vehicle Type',
              hintText: 'e.g. Sedan, Motorcycle',
              controller: _vehicleTypeController,
              readOnly: state.isSaving,
              textInputAction: TextInputAction.next,
            ),
            Divider(
              height: 1,
              thickness: 1,
              indent: 52,
              endIndent: AppSpacing.lg,
              color: colorScheme.outlineVariant.withValues(alpha: 0.65),
            ),
            _ProfileTextField(
              icon: LucideIcons.hash,
              label: 'Plate Number',
              hintText: 'e.g. ABC-1234',
              controller: _plateNumberController,
              readOnly: state.isSaving,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.characters,
              useTabular: true,
              onSubmitted: (_) {
                if (!state.isSaving) unawaited(_submitSave());
              },
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        child: Text(
          'Vehicle information is updated in your active driver profile.',
          style: textStyles.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ),
      if (state.errorMessage != null) ...[
        const SizedBox(height: AppSpacing.md),
        Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ExcludeSemantics(
                  child: Icon(
                    LucideIcons.circle_alert,
                    size: 15,
                    color: colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  state.errorMessage!,
                  style: textStyles.bodySmall?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: AppSpacing.xxl),
      SizedBox(
        height: AppSize.controlHeight,
        width: double.infinity,
        child: FilledButton(
          key: const ValueKey<String>('driver-account-details-save'),
          onPressed: state.isSaving ? null : _submitSave,
          style:
              FilledButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                elevation: 0,
                enableFeedback: false,
                splashFactory: NoSplash.splashFactory,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.focused)) {
                    return colorScheme.onPrimary.withValues(alpha: 0.16);
                  }
                  return Colors.transparent;
                }),
              ),
          child: state.isSaving
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : const Text('Save Changes'),
        ),
      ),
    ];
  }

  String _initials(String name) {
    if (name.isEmpty) return 'D';
    final parts = name.split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }
}

class const _ProfileTextField({
  required this.icon,
  required this.label,
  required this.controller,
  this.hintText,
  this.readOnly = false,
  this.textInputAction,
  this.textCapitalization = TextCapitalization.words,
  this.useTabular = false,
  this.onSubmitted,
}) extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? hintText;
  final TextEditingController controller;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool useTabular;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final valueStyle =
        (useTabular ? textStyles.bodyLarge?.tabular : textStyles.bodyLarge)
            ?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            );

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
              child: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textStyles.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  key: ValueKey<String>('driver-account-field-$label'),
                  controller: controller,
                  readOnly: readOnly,
                  showCursor: !readOnly,
                  textInputAction: textInputAction,
                  textCapitalization: textCapitalization,
                  onSubmitted: onSubmitted,
                  style: valueStyle,
                  decoration: InputDecoration(
                    isDense: true,
                    filled: false,
                    hintText: hintText,
                    hintStyle: textStyles.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.6,
                      ),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
