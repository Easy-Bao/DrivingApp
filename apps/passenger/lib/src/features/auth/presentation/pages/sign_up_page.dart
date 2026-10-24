import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/auth/domain/validators/phone_number_validator.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/auth/presentation/bloc/sign_up/sign_up_bloc.dart';
import 'package:passenger/src/features/auth/presentation/validation/auth_form_validator.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/features/settings/settings_routes.dart';

class const SignupPage({super.key, required this.signUpBloc})
    extends StatelessWidget {
  final SignUpBloc signUpBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignUpBloc>(
      create: (_) => signUpBloc,
      child: const _SignupPageContent(),
    );
  }
}

class const _SignupPageContent() extends StatefulWidget {
  @override
  State<_SignupPageContent> createState() => _SignupPageContentState();
}

class _SignupPageContentState extends State<_SignupPageContent> {
  final TextEditingController _passengerNameController =
      TextEditingController();
  final TextEditingController _passengerPhoneController =
      TextEditingController();
  final TextEditingController _passengerEmailController =
      TextEditingController();
  final TextEditingController _passengerPasswordController =
      TextEditingController();

  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isPasswordInputVisible = false;

  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _submissionError;

  @override
  void dispose() {
    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _passengerNameController.dispose();
    _passengerPhoneController.dispose();
    _passengerEmailController.dispose();
    _passengerPasswordController.dispose();
    super.dispose();
  }

  void _submitRegistration(BuildContext context) {
    if (BlocProvider.of<SignUpBloc>(context).state is SignUpLoading) {
      return;
    }
    FocusScope.of(context).unfocus();
    final name = _passengerNameController.text.trim();
    final rawPhone = _passengerPhoneController.text.trim();
    final email = _passengerEmailController.text.trim();
    final password = _passengerPasswordController.text;

    setState(() {
      _submissionError = null;
      _nameError = authFormValidator.name(name);
      _phoneError = authFormValidator.phone(rawPhone);
      _emailError = authFormValidator.email(email);
      _passwordError = authFormValidator.password(password);
    });

    if (_nameError != null ||
        _phoneError != null ||
        _emailError != null ||
        _passwordError != null) {
      (_nameError != null
              ? _nameFocus
              : _phoneError != null
              ? _phoneFocus
              : _emailError != null
              ? _emailFocus
              : _passwordFocus)
          .requestFocus();
      return;
    }

    final formattedPhone = PhoneNumberValidator.normalizePHNumber(rawPhone);
    BlocProvider.of<SignUpBloc>(context).add(
      SignUpSubmitted(
        name: name,
        email: email,
        phone: formattedPhone,
        password: password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignUpBloc, SignUpState>(
      listener: (context, state) {
        if (state is SignUpSuccess) {
          TextInput.finishAutofillContext();
          BlocProvider.of<SessionBloc>(context).add(
            SessionAuthenticatedRequested(
              passengerId: state.credentials.passengerId,
              passengerName: state.credentials.passengerName,
            ),
          );
          context.goNamed(HomeRoutes.home);
        } else if (state is SignUpNeedsVerification) {
          unawaited(
            context.pushNamed(
              AuthRoutes.verifyOtp,
              extra: {'email': state.email},
            ),
          );
        } else if (state is SignUpFailure) {
          setState(() => _submissionError = state.errorMessage);
        }
      },
      builder: (context, state) {
        final isLoading = state is SignUpLoading;
        return AppAuthLayout(
          onBack: () => context.pop(),
          title: 'Create an account',
          description: 'Sign up to book and manage your rides.',
          footer: TextButton(
            onPressed: () => context.pushNamed(SettingsRoutes.terms),
            child: Text.rich(
              const TextSpan(
                text: 'By creating an account, you agree to the EasyRide ',
                children: [
                  TextSpan(
                    text: 'Terms of Service.',
                    style: TextStyle(decoration: TextDecoration.underline),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          children: [
            if (_submissionError != null) ...[
              AppErrorBanner(
                message: _submissionError!,
                onRetry: () => _submitRegistration(context),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Full name', style: context.textStyles.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _passengerNameController,
                    focusNode: _nameFocus,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    onChanged: (_) => setState(() {
                      _nameError = null;
                      _submissionError = null;
                    }),
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      errorText: _nameError,
                      prefixIcon: const Icon(LucideIcons.user, size: 18),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Mobile number', style: context.textStyles.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    key: const ValueKey<String>('passenger-signup-phone'),
                    controller: _passengerPhoneController,
                    focusNode: _phoneFocus,
                    enabled: !isLoading,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.telephoneNumberNational,
                    ],
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {
                      _phoneError = null;
                      _submissionError = null;
                    }),
                    decoration: InputDecoration(
                      hintText: '09171234567',
                      errorText: _phoneError,
                      prefixIcon: const Icon(LucideIcons.phone, size: 18),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Email', style: context.textStyles.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _passengerEmailController,
                    focusNode: _emailFocus,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    onChanged: (_) => setState(() {
                      _emailError = null;
                      _submissionError = null;
                    }),
                    decoration: InputDecoration(
                      hintText: 'you@example.com',
                      errorText: _emailError,
                      prefixIcon: const Icon(LucideIcons.mail, size: 18),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Password', style: context.textStyles.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: _passengerPasswordController,
                    focusNode: _passwordFocus,
                    enabled: !isLoading,
                    obscureText: !_isPasswordInputVisible,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => _submitRegistration(context),
                    onChanged: (_) => setState(() {
                      _passwordError = null;
                      _submissionError = null;
                    }),
                    decoration: InputDecoration(
                      hintText: 'Create a password',
                      errorText: _passwordError,
                      helperText: 'Use at least 8 characters.',
                      helperMaxLines: 2,
                      prefixIcon: const Icon(LucideIcons.lock, size: 18),
                      suffixIcon: IconButton(
                        tooltip: _isPasswordInputVisible
                            ? 'Hide password'
                            : 'Show password',
                        onPressed: isLoading
                            ? null
                            : () => setState(
                                () => _isPasswordInputVisible =
                                    !_isPasswordInputVisible,
                              ),
                        icon: Icon(
                          _isPasswordInputVisible
                              ? LucideIcons.eye
                              : LucideIcons.eye_off,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: isLoading ? null : () => _submitRegistration(context),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: context.colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Create account'),
            ),
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context.pushNamed(AuthRoutes.signin),
                  child: const Text('Sign in'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
