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
  static const _phonePrefix = '+63';

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _plateNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _applyAccount(BlocProvider.of<AccountCubit>(context).state.account);
  }

  List<TextEditingController> get _controllers => [
    _nameController,
    _phoneController,
    _emailController,
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
    _nameController.text = account.name;
    _phoneController.text = _localPhoneNumber(account.phone);
    _emailController.text = account.email;
    _vehicleTypeController.text = account.vehicleType;
    _plateNumberController.text = account.plateNumber;
  }

  String _localPhoneNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('63')) return digits.substring(2);
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

  String get _pageTitle => switch (widget.section) {
    AccountDetailsSection.personal => 'Personal Details',
    AccountDetailsSection.vehicle => 'Vehicle Information',
  };

  Future<void> _submitSave() async {
    final cubit = BlocProvider.of<AccountCubit>(context);
    final currentAccount = cubit.state.account;
    final isPersonal = widget.section == AccountDetailsSection.personal;
    final name = isPersonal ? _nameController.text.trim() : currentAccount.name;
    final vehicleType = isPersonal
        ? currentAccount.vehicleType
        : _vehicleTypeController.text.trim();
    final plateNumber = isPersonal
        ? currentAccount.plateNumber
        : _plateNumberController.text.trim();

    final success = await cubit.updateAccount(
      name: name,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
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
                padding: const EdgeInsets.fromLTRB(
                  AppLayout.pagePaddingWide,
                  AppLayout.pagePadding,
                  AppLayout.pagePaddingWide,
                  AppSpacing.xxl * 2,
                ),
                children: [
                  _buildHeader(),
                  const SizedBox(height: AppSpacing.xxl),
                  AppSurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: widget.section == AccountDetailsSection.personal
                          ? _buildPersonalFields(state)
                          : _buildVehicleFields(state),
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

  Widget _buildHeader() {
    final isPersonal = widget.section == AccountDetailsSection.personal;
    final displayName = _nameController.text.trim();
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
    return [
      _ProfileTextField(
        label: 'Full Name',
        controller: _nameController,
        readOnly: state.isSaving,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 22),
      _buildPhoneField(),
      const SizedBox(height: 22),
      _ProfileTextField(
        label: 'Email',
        controller: _emailController,
        readOnly: true,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.none,
      ),
      const SizedBox(height: 10),
      Text(
        'Phone number and email are verified account identifiers.',
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

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ProfileFieldLabel('Mobile Number'),
        const SizedBox(height: 9),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              width: 88,
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colorScheme.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Text(
                _phonePrefix,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const ValueKey<String>('driver-personal-phone-number'),
                controller: _phoneController,
                readOnly: true,
                showCursor: false,
                keyboardType: TextInputType.phone,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
                textInputAction: TextInputAction.next,
                decoration: _fieldDecoration(context, hintText: '917 000 0001'),
              ),
            ),
          ],
        ),
      ],
    );
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
  this.keyboardType,
  this.textInputAction,
  this.textCapitalization = TextCapitalization.words,
}) extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final TextInputType? keyboardType;
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
          keyboardType: keyboardType,
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
