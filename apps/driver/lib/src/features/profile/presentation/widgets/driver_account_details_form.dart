import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:design_system/design_system.dart';

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
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: widget.onBack ?? () => context.pop(),
              icon: const Icon(LucideIcons.arrow_left),
            ),
            title: Text(_pageTitle),
            centerTitle: true,
            actions: const [SizedBox(width: 24)],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  isPersonal
                      ? AppLayout.pagePadding
                      : AppLayout.pagePaddingWide,
                  AppLayout.pagePadding,
                  isPersonal
                      ? AppLayout.pagePadding
                      : AppLayout.pagePaddingWide,
                  AppSpacing.xxl * 2,
                ),
                children: [
                  _buildHeader(state.account),
                  const SizedBox(height: AppSpacing.xxl),
                  if (isPersonal)
                    ..._buildPersonalFields(state)
                  else
                    AppSurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: _buildVehicleFields(state),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(AccountSnapshot account) {
    final isPersonal = widget.section == AccountDetailsSection.personal;
    final displayName = account.name.trim();
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: context.colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isPersonal
              ? Text(
                  _initials(displayName),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: context.colorScheme.onSecondaryContainer,
                  ),
                )
              : Icon(
                  LucideIcons.car_front,
                  size: 36,
                  color: context.colorScheme.onSecondaryContainer,
                ),
        ),
        const SizedBox(height: 14),
        Text(
          isPersonal
              ? 'Your contact details'
              : 'Your registered service vehicle',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: context.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  List<Widget> _buildPersonalFields(AccountState state) {
    final account = state.account;
    return [
      if (state.isLoading) const LinearProgressIndicator(),
      if (state.errorMessage != null) ...[
        AppErrorBanner(
          message: state.errorMessage!,
          onRetry: () => BlocProvider.of<AccountCubit>(context).load(),
          onDismiss: () =>
              BlocProvider.of<AccountCubit>(context).dismissError(),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
      const Divider(height: 1),
      _buildContactDetail('Full name', account.name),
      const Divider(height: 1),
      _buildContactDetail('Mobile number', account.phone),
      const Divider(height: 1),
      _buildContactDetail('Email', account.email),
      const SizedBox(height: AppSpacing.lg),
      Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(
              child: Icon(
                LucideIcons.lock_keyhole,
                size: 16,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Phone number and email are verified account identifiers and can’t be edited here.',
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildContactDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value.trim().isEmpty ? 'Not provided' : value,
            style: context.textStyles.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVehicleFields(AccountState state) {
    return [
      _ProfileTextField(
        label: 'Vehicle Type',
        controller: _vehicleTypeController,
        readOnly: state.isSaving,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 22),
      _ProfileTextField(
        label: 'Plate Number',
        controller: _plateNumberController,
        readOnly: state.isSaving,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.characters,
      ),
      const SizedBox(height: 10),
      Text(
        'Vehicle information is updated in your active driver profile.',
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: context.colorScheme.onSurfaceVariant),
      ),
      if (state.errorMessage != null) ...[
        const SizedBox(height: 12),
        Text(
          state.errorMessage!,
          style: TextStyle(color: context.colorScheme.error, fontSize: 13),
        ),
      ],
      const SizedBox(height: 24),
      ElevatedButton(
        key: const ValueKey<String>('driver-account-details-save'),
        onPressed: state.isSaving ? null : _submitSave,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, AppSize.minimumTouchTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: state.isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save Changes'),
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
  required this.label,
  required this.controller,
  this.readOnly = false,
  this.textInputAction,
  this.textCapitalization = TextCapitalization.words,
}) extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProfileFieldLabel(label),
        const SizedBox(height: 9),
        TextField(
          key: ValueKey<String>('driver-account-field-$label'),
          controller: controller,
          readOnly: readOnly,
          showCursor: !readOnly,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          decoration: _fieldDecoration(context),
        ),
      ],
    );
  }
}

class const _ProfileFieldLabel(this.label) extends StatelessWidget {
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: context.colorScheme.onSurfaceVariant),
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context, {
  String? hintText,
  String? errorText,
}) {
  final border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.lg),
    borderSide: BorderSide(color: context.colorScheme.outlineVariant),
  );
  return InputDecoration(
    hintText: hintText,
    errorText: errorText,
    filled: true,
    fillColor: context.colorScheme.surface,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppLayout.pagePadding,
      vertical: 16,
    ),
    border: border,
    enabledBorder: border,
    focusedBorder: border.copyWith(
      borderSide: BorderSide(color: context.colorScheme.primary, width: 1.5),
    ),
    errorBorder: border.copyWith(
      borderSide: BorderSide(color: context.colorScheme.error),
    ),
    focusedErrorBorder: border.copyWith(
      borderSide: BorderSide(color: context.colorScheme.error, width: 1.5),
    ),
  );
}
