import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/profile/bloc/account/account_cubit.dart';
import 'package:driver_app/src/features/profile/bloc/account/account_state.dart';
import 'package:driver_app/src/features/profile/domain/entities/driver_account_snapshot.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverProfileInfoPage extends StatefulWidget {
  const DriverProfileInfoPage({super.key});

  @override
  State<DriverProfileInfoPage> createState() => _DriverProfileInfoPageState();
}

class _DriverProfileInfoPageState extends State<DriverProfileInfoPage> {
  static const _phonePrefix = '+63';

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _vehicleTypeController = TextEditingController();
  final _plateNumberController = TextEditingController();

  String _initialName = '';
  String _initialPhone = '';
  String _initialEmail = '';
  String _initialVehicleType = '';
  String _initialPlateNumber = '';
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
    _nameController.addListener(_updateDirtyState);
    _phoneController.addListener(_updateDirtyState);
    _emailController.addListener(_updateDirtyState);
    _vehicleTypeController.addListener(_updateDirtyState);
    _plateNumberController.addListener(_updateDirtyState);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _vehicleTypeController.dispose();
    _plateNumberController.dispose();
    super.dispose();
  }

  void _applyAccount(DriverAccountSnapshot account) {
    final phoneNumber = _localPhoneNumber(account.phone);
    _isApplyingAccount = true;
    _nameController.text = account.name;
    _phoneController.text = phoneNumber;
    _emailController.text = account.email;
    _vehicleTypeController.text = account.vehicleType;
    _plateNumberController.text = account.plateNumber;
    _initialName = account.name.trim();
    _initialPhone = _formatPhone(phoneNumber);
    _initialEmail = account.email.trim();
    _initialVehicleType = account.vehicleType.trim();
    _initialPlateNumber = account.plateNumber.trim();
    _isDirty = false;
    _isApplyingAccount = false;
  }

  void _updateDirtyState() {
    if (_isApplyingAccount || !mounted) return;
    final dirty = _draftHasChanges;
    if (_isDirty == dirty) return;
    setState(() => _isDirty = dirty);
  }

  bool get _draftHasChanges =>
      _nameController.text.trim() != _initialName ||
      _formatPhone(_phoneController.text) != _initialPhone ||
      _emailController.text.trim() != _initialEmail ||
      _vehicleTypeController.text.trim() != _initialVehicleType ||
      _plateNumberController.text.trim() != _initialPlateNumber;

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

  Future<void> _save() async {
    final accountCubit = BlocProvider.of<DriverAccountCubit>(context);
    if (!_isDirty || accountCubit.state.isSaving) return;
    _clearErrors();

    final name = _nameController.text.trim();
    final phone = _formatPhone(_phoneController.text);
    final email = _emailController.text.trim();
    final vehicleType = _vehicleTypeController.text.trim();
    final plateNumber = _plateNumberController.text.trim();
    var hasError = false;

    if (name.isEmpty) {
      _nameError = 'Name is required';
      hasError = true;
    }
    if (_phoneController.text.replaceAll(RegExp(r'[^0-9]'), '').length < 10) {
      _phoneError = 'Enter a valid mobile number';
      hasError = true;
    }
    if (email.isEmpty) {
      _emailError = 'Email is required';
      hasError = true;
    } else if (!email.contains('@')) {
      _emailError = 'Please enter a valid email';
      hasError = true;
    }
    if (vehicleType.isEmpty) {
      _vehicleTypeError = 'Vehicle type is required';
      hasError = true;
    }
    if (plateNumber.isEmpty) {
      _plateNumberError = 'Plate number is required';
      hasError = true;
    }
    if (hasError) {
      setState(() {});
      return;
    }

    final didUpdate = await accountCubit.updateAccount(
      name: name,
      phone: phone,
      email: email,
      vehicleType: vehicleType,
      plateNumber: plateNumber,
    );
    if (!mounted) return;

    if (!didUpdate) {
      CustomToast.show(
        context,
        accountCubit.state.errorMessage ??
            'We could not update your profile. Please try again.',
        isError: true,
      );
      return;
    }

    _applyAccount(accountCubit.state.account);
    setState(() {});
    CustomToast.show(context, 'Profile updated successfully!');
  }

  void _clearErrors() {
    _nameError = null;
    _phoneError = null;
    _emailError = null;
    _vehicleTypeError = null;
    _plateNumberError = null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DriverAccountCubit, DriverAccountState>(
      listenWhen: (previous, current) => previous.account != current.account,
      listener: (_, state) {
        if (!_isDirty && !state.isSaving) _applyAccount(state.account);
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            icon: const Icon(
              LucideIcons.arrow_left,
              color: AppTheme.primaryColor,
              size: 23,
            ),
          ),
          title: const Text('Profile Info'),
          centerTitle: true,
          actions: [
            if (_isDirty)
              BlocBuilder<DriverAccountCubit, DriverAccountState>(
                buildWhen: (previous, current) =>
                    previous.isSaving != current.isSaving,
                builder: (context, state) => TextButton(
                  key: const ValueKey<String>('driver-profile-save'),
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
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 34),
                    _buildTextField(
                      label: 'Full Name',
                      controller: _nameController,
                      errorText: _nameError,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),
                    _buildPhoneField(),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      errorText: _emailError,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'Vehicle Type',
                      controller: _vehicleTypeController,
                      errorText: _vehicleTypeError,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      label: 'Plate Number',
                      controller: _plateNumberController,
                      errorText: _plateNumberError,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final displayName = _nameController.text.trim();
    final initials = displayName.isEmpty
        ? 'D'
        : displayName
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part[0])
              .join()
              .toUpperCase();
    return Column(
      children: [
        Container(
          width: 116,
          height: 116,
          decoration: const BoxDecoration(
            color: AppTheme.secondaryColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Driver profile',
          style: TextStyle(
            color: AppTheme.tertiaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? errorText,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        const SizedBox(height: 9),
        TextField(
          key: ValueKey<String>('driver-profile-field-$label'),
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: label == 'Plate Number'
              ? TextCapitalization.characters
              : TextCapitalization.words,
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
          decoration: _fieldDecoration(errorText: errorText),
        ),
      ],
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Mobile Number'),
        const SizedBox(height: 9),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 62,
              width: 94,
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(17),
                border: Border.all(color: AppTheme.borderSide),
              ),
              alignment: Alignment.center,
              child: const Text(
                _phonePrefix,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                key: const ValueKey<String>('driver-profile-phone-number'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
                decoration: _fieldDecoration(
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

  InputDecoration _fieldDecoration({String? hintText, String? errorText}) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(17),
      borderSide: const BorderSide(color: AppTheme.borderSide),
    );
    return InputDecoration(
      hintText: hintText,
      errorText: errorText,
      filled: true,
      fillColor: AppTheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppTheme.cancel),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppTheme.cancel, width: 1.5),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppTheme.primaryColor.withValues(alpha: 0.48),
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.7,
      ),
    );
  }
}
