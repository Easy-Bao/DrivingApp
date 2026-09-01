import 'package:driver/src/features/profile/presentation/bloc/account/account_cubit.dart';
import 'package:driver/src/features/profile/presentation/bloc/account/account_state.dart';
import 'package:driver/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:design_system/design_system.dart';

enum DriverAccountDetailsSection { personal, vehicle }

class const DriverAccountDetailsForm({
  super.key,
  required this.section,
  this.onBack,
}) extends StatefulWidget {
  final DriverAccountDetailsSection section;
  final VoidCallback? onBack;

  @override
  State<DriverAccountDetailsForm> createState() =>
      _DriverAccountDetailsFormState();
}

class _DriverAccountDetailsFormState extends State<DriverAccountDetailsForm> {
  static const _phonePrefix = '+63';

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _plateNumberController = TextEditingController();

  DriverAccountSnapshot _initialAccount = const DriverAccountSnapshot();
  bool _isApplyingAccount = false;
  bool _isDirty = false;
  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _vehicleTypeError;
  String? _plateNumberError;

  @override
  void initState() {
    super.initState();
    _applyAccount(BlocProvider.of<DriverAccountCubit>(context).state.account);
    for (final controller in _controllers) {
      controller.addListener(_handleDraftChanged);
    }
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

  void _applyAccount(DriverAccountSnapshot account) {
    _isApplyingAccount = true;
    _nameController.text = account.name;
    _phoneController.text = _localPhoneNumber(account.phone);
    _emailController.text = account.email;
    _vehicleTypeController.text = account.vehicleType;
    _plateNumberController.text = account.plateNumber;
    _initialAccount = account;
    _isDirty = false;
    _isApplyingAccount = false;
  }

  void _handleDraftChanged() {
    if (_isApplyingAccount || !mounted) return;
    setState(() => _isDirty = _draftHasChanges);
  }

  bool get _draftHasChanges {
    return switch (widget.section) {
      DriverAccountDetailsSection.personal =>
        _nameController.text.trim() != _initialAccount.name.trim() ||
            _formatPhone(_phoneController.text) !=
                _formatPhone(_initialAccount.phone) ||
            _emailController.text.trim() != _initialAccount.email.trim(),
      DriverAccountDetailsSection.vehicle =>
        _vehicleTypeController.text.trim() !=
                _initialAccount.vehicleType.trim() ||
            _plateNumberController.text.trim() !=
                _initialAccount.plateNumber.trim(),
    };
  }

  Future<void> _save() async {
    final accountCubit = BlocProvider.of<DriverAccountCubit>(context);
    if (!_isDirty || accountCubit.state.isSaving) return;

    _clearErrors();
    if (!_validate()) {
      setState(() {});
      return;
    }

    final current = accountCubit.state.account;
    final didUpdate = await accountCubit.updateAccount(
      name: widget.section == DriverAccountDetailsSection.personal
          ? _nameController.text.trim()
          : current.name,
      phone: widget.section == DriverAccountDetailsSection.personal
          ? _formatPhone(_phoneController.text)
          : current.phone,
      email: widget.section == DriverAccountDetailsSection.personal
          ? _emailController.text.trim()
          : current.email,
      vehicleType: widget.section == DriverAccountDetailsSection.vehicle
          ? _vehicleTypeController.text.trim()
          : current.vehicleType,
      plateNumber: widget.section == DriverAccountDetailsSection.vehicle
          ? _plateNumberController.text.trim()
          : current.plateNumber,
    );
    if (!mounted) return;

    if (!didUpdate) {
      _showMessage(
        accountCubit.state.errorMessage ??
            'We could not update your details. Please try again.',
      );
      return;
    }

    _applyAccount(accountCubit.state.account);
    setState(() {});
    _showMessage('$_pageTitle updated successfully.');
  }

  bool _validate() {
    switch (widget.section) {
      case DriverAccountDetailsSection.personal:
        if (_nameController.text.trim().isEmpty) {
          _nameError = 'Name is required';
        }
        if (_phoneController.text.replaceAll(RegExp(r'[^0-9]'), '').length <
            10) {
          _phoneError = 'Enter a valid mobile number';
        }
        final email = _emailController.text.trim();
        if (email.isEmpty) {
          _emailError = 'Email is required';
        } else if (!email.contains('@')) {
          _emailError = 'Please enter a valid email';
        }
      case DriverAccountDetailsSection.vehicle:
        if (_vehicleTypeController.text.trim().isEmpty) {
          _vehicleTypeError = 'Vehicle type is required';
        }
        if (_plateNumberController.text.trim().isEmpty) {
          _plateNumberError = 'Plate number is required';
        }
    }
    return [
      _nameError,
      _phoneError,
      _emailError,
      _vehicleTypeError,
      _plateNumberError,
    ].every((error) => error == null);
  }

  void _clearErrors() {
    _nameError = null;
    _phoneError = null;
    _emailError = null;
    _vehicleTypeError = null;
    _plateNumberError = null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('63')) return '+$digits';
    if (digits.startsWith('0')) return '$_phonePrefix${digits.substring(1)}';
    return '$_phonePrefix$digits';
  }

  String _localPhoneNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('63')) return digits.substring(2);
    if (digits.startsWith('0')) return digits.substring(1);
    return digits;
  }

  String get _pageTitle => switch (widget.section) {
    DriverAccountDetailsSection.personal => 'Personal Details',
    DriverAccountDetailsSection.vehicle => 'Vehicle Information',
  };

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverAccountCubit, DriverAccountState>(
      listenWhen: (previous, current) => previous.account != current.account,
      listener: (_, state) {
        if (!_isDirty && !state.isSaving) {
          _applyAccount(state.account);
          setState(() {});
        }
      },
      child: Scaffold(
        backgroundColor: context.canvasColor,
        appBar: AppBar(
          leading: IconButton(
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onPressed: widget.onBack ?? () => context.pop(),
            icon: const Icon(LucideIcons.arrow_left),
          ),
          title: Text(_pageTitle),
          centerTitle: true,
          actions: [
            if (_isDirty)
              BlocBuilder<DriverAccountCubit, DriverAccountState>(
                buildWhen: (previous, current) =>
                    previous.isSaving != current.isSaving,
                builder: (context, state) => TextButton(
                  key: const ValueKey<String>('driver-account-details-save'),
                  onPressed: state.isSaving ? null : _save,
                  child: state.isSaving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.4),
                        )
                      : const Text('Save'),
                ),
              )
            else
              const SizedBox(width: 24),
          ],
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
              children: [
                _buildHeader(),
                const SizedBox(height: 30),
                if (widget.section == DriverAccountDetailsSection.personal)
                  ..._buildPersonalFields()
                else
                  ..._buildVehicleFields(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isPersonal = widget.section == DriverAccountDetailsSection.personal;
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

  List<Widget> _buildPersonalFields() {
    return [
      _DriverProfileTextField(
        label: 'Full Name',
        controller: _nameController,
        errorText: _nameError,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 22),
      _buildPhoneField(),
      const SizedBox(height: 22),
      _DriverProfileTextField(
        label: 'Email',
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        errorText: _emailError,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.none,
      ),
    ];
  }

  List<Widget> _buildVehicleFields() {
    return [
      _DriverProfileTextField(
        label: 'Vehicle Type',
        controller: _vehicleTypeController,
        errorText: _vehicleTypeError,
        textInputAction: TextInputAction.next,
      ),
      const SizedBox(height: 22),
      _DriverProfileTextField(
        label: 'Plate Number',
        controller: _plateNumberController,
        errorText: _plateNumberError,
        textInputAction: TextInputAction.done,
        textCapitalization: TextCapitalization.characters,
      ),
    ];
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DriverProfileFieldLabel('Mobile Number'),
        const SizedBox(height: 9),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              width: 88,
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: context.colorScheme.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Text(
                _phonePrefix,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const ValueKey<String>('driver-personal-phone-number'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: _fieldDecoration(
                  context,
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

  String _initials(String name) {
    if (name.isEmpty) return 'D';
    final parts = name.split(RegExp(r'\s+'));
    return parts.take(2).map((part) => part[0]).join().toUpperCase();
  }
}

class const _DriverProfileTextField({
  required this.label,
  required this.controller,
  this.errorText,
  this.keyboardType,
  this.textInputAction,
  this.textCapitalization = TextCapitalization.words,
}) extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DriverProfileFieldLabel(label),
        const SizedBox(height: 9),
        TextField(
          key: ValueKey<String>('driver-account-field-$label'),
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          decoration: _fieldDecoration(context, errorText: errorText),
        ),
      ],
    );
  }
}

class const _DriverProfileFieldLabel(this.label) extends StatelessWidget {
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
    borderRadius: BorderRadius.circular(17),
    borderSide: BorderSide(color: context.colorScheme.outlineVariant),
  );
  return InputDecoration(
    hintText: hintText,
    errorText: errorText,
    filled: true,
    fillColor: context.colorScheme.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
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
