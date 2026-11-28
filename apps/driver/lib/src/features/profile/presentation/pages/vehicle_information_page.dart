import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/profile/domain/entities/account_snapshot.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';

class const VehicleInformationPage({super.key, this.onBack})
    extends StatefulWidget {
  final VoidCallback? onBack;

  @override
  State<VehicleInformationPage> createState() => _VehicleInformationPageState();
}

class _VehicleInformationPageState extends State<VehicleInformationPage> {
  final _vehicleTypeController = TextEditingController();
  final _plateNumberController = TextEditingController();
  String _initialVehicleType = '';
  String _initialPlateNumber = '';
  String? _validationError;

  bool get _hasChanges =>
      _vehicleTypeController.text.trim() != _initialVehicleType ||
      _plateNumberController.text.trim() != _initialPlateNumber;

  @override
  void initState() {
    super.initState();
    _applyAccount(BlocProvider.of<AccountCubit>(context).state.account);
    _vehicleTypeController.addListener(_handleFieldChanged);
    _plateNumberController.addListener(_handleFieldChanged);
  }

  @override
  void dispose() {
    _vehicleTypeController.removeListener(_handleFieldChanged);
    _plateNumberController.removeListener(_handleFieldChanged);
    _vehicleTypeController.dispose();
    _plateNumberController.dispose();
    super.dispose();
  }

  void _handleFieldChanged() {
    if (!mounted) return;
    final cubit = BlocProvider.of<AccountCubit>(context);
    if (cubit.state.errorMessage != null) {
      cubit.dismissError();
    }
    setState(() => _validationError = null);
  }

  void _applyAccount(AccountSnapshot account) {
    _initialVehicleType = account.vehicleType.trim();
    _initialPlateNumber = account.plateNumber.trim();
    _vehicleTypeController.text = account.vehicleType;
    _plateNumberController.text = account.plateNumber;
  }

  Future<void> _submitSave() async {
    final vehicleType = _vehicleTypeController.text.trim();
    final plateNumber = _plateNumberController.text.trim();
    if (vehicleType.isEmpty) {
      setState(() => _validationError = 'Enter your vehicle type.');
      return;
    }
    if (plateNumber.isEmpty) {
      setState(() => _validationError = 'Enter your plate number.');
      return;
    }
    if (!_hasChanges) return;

    final cubit = BlocProvider.of<AccountCubit>(context);
    final currentAccount = cubit.state.account;
    final success = await cubit.updateAccount(
      name: currentAccount.name,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
    );
    if (!mounted || !context.mounted) return;
    if (success) {
      final onBack = widget.onBack;
      if (onBack != null) {
        AppSnackBar.show(context, 'Vehicle information updated.');
        onBack();
      } else {
        context.pop<bool>(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppSecondaryPage(
      title: 'Vehicle Information',
      onBack: widget.onBack ?? () => context.pop(),
      maxWidth: 560,
      child: BlocConsumer<AccountCubit, AccountState>(
        listenWhen: (previous, current) => previous.account != current.account,
        listener: (_, state) => _applyAccount(state.account),
        builder: (context, state) {
          final colorScheme = context.colorScheme;
          final textStyles = context.textStyles;

          return LayoutBuilder(
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
                  Column(
                    children: [
                      ExcludeSemantics(
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerLowest,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            LucideIcons.car_front,
                            size: 28,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Your registered service vehicle',
                        textAlign: TextAlign.center,
                        style: textStyles.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _VehicleField(
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
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.65,
                          ),
                        ),
                        _VehicleField(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: Text(
                      'Vehicle information is updated in your active driver profile.',
                      style: textStyles.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                  if ((_validationError ?? state.errorMessage)
                      case final errorMessage?) ...[
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
                              errorMessage,
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
                      key: const ValueKey<String>(
                        'driver-account-details-save',
                      ),
                      onPressed: state.isSaving || !_hasChanges
                          ? null
                          : _submitSave,
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
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class const _VehicleField({
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
