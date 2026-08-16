import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/core/utils/phone_number_validator.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/auth/bloc/sign_up/sign_up_bloc.dart';
import 'package:passenger_app/src/features/auth/view/validation/auth_form_validator.dart';
import 'package:passenger_app/src/features/auth/view/widgets/social_login_widget.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/shared/widgets/app_back_button_widget.dart';
import 'package:shared_ui/shared_ui.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignUpBloc>(
      create: (context) => Modular.get<SignUpBloc>(),
      child: const _SignupPageContent(),
    );
  }
}

class _SignupPageContent extends StatefulWidget {
  const _SignupPageContent();

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

  bool _isPasswordInputVisible = false;

  String? _nameError;
  String? _phoneError;
  String? _emailError;
  String? _passwordError;
  String? _submissionError;

  @override
  void dispose() {
    _passengerNameController.dispose();
    _passengerPhoneController.dispose();
    _passengerEmailController.dispose();
    _passengerPasswordController.dispose();
    super.dispose();
  }

  void _submitRegistration(BuildContext context) {
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
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: AppBackButtonWidget.plain(onPressed: () => context.pop()),
        ),
        centerTitle: true,
        title: Image.asset(
          'assets/logo/applogo.png',
          package: 'shared_ui',
          height: 140,
          fit: BoxFit.cover,
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<SignUpBloc, SignUpState>(
          listener: (context, state) {
            if (state is SignUpSuccess) {
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
            final errorMessage = _submissionError;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            const Center(
                              child: Column(
                                children: [
                                  Text(
                                    'Create Account',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Enter your details to create your account',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.tertiaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 28),
                            if (errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.cancel.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppTheme.cancel.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  errorMessage,
                                  style: const TextStyle(
                                    color: AppTheme.cancel,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'FULL NAME',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.tertiaryColor,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              controller: _passengerNameController,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                setState(() {
                                  _nameError = null;
                                  _submissionError = null;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: 'Full Name',
                                errorText: _nameError,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Icon(
                                    LucideIcons.user,
                                    size: 20,
                                    color: Color(0xFF495057),
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(36),
                                  borderSide: const BorderSide(
                                    color: AppTheme.borderSide,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(36),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(36),
                                  borderSide: const BorderSide(
                                    color: AppTheme.cancel,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(36),
                                  borderSide: const BorderSide(
                                    color: AppTheme.cancel,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'PHONE NUMBER',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.tertiaryColor,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              controller: _passengerPhoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                setState(() {
                                  _phoneError = null;
                                  _submissionError = null;
                                });
                              },
                              decoration: InputDecoration(
                                hintText: '09171234567',
                                errorText: _phoneError,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Icon(
                                    LucideIcons.phone,
                                    size: 20,
                                    color: Color(0xFF495057),
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(36),
                                  borderSide: const BorderSide(
                                    color: AppTheme.borderSide,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(36),
                                  borderSide: const BorderSide(
                                    color: AppTheme.primaryColor,
                                    width: 1.5,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(36),
                                  borderSide: const BorderSide(
                                    color: AppTheme.cancel,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(36),
                                  borderSide: const BorderSide(
                                    color: AppTheme.cancel,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'EMAIL ADDRESS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.tertiaryColor,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Hero(
                              tag: 'auth_email_field',
                              child: Material(
                                type: MaterialType.transparency,
                                child: TextField(
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  controller: _passengerEmailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) {
                                    setState(() {
                                      _emailError = null;
                                      _submissionError = null;
                                    });
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    errorText: _emailError,
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Icon(
                                        LucideIcons.mail,
                                        size: 20,
                                        color: Color(0xFF495057),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: const BorderSide(
                                        color: AppTheme.borderSide,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: const BorderSide(
                                        color: AppTheme.cancel,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: const BorderSide(
                                        color: AppTheme.cancel,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'PASSWORD',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.tertiaryColor,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Hero(
                              tag: 'auth_password_field',
                              child: Material(
                                type: MaterialType.transparency,
                                child: TextField(
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  obscureText: !_isPasswordInputVisible,
                                  controller: _passengerPasswordController,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (_) {
                                    setState(() {
                                      _passwordError = null;
                                      _submissionError = null;
                                    });
                                  },
                                  onSubmitted: (_) =>
                                      _submitRegistration(context),
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    errorText: _passwordError,
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Icon(
                                        LucideIcons.lock,
                                        size: 20,
                                        color: Color(0xFF495057),
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _isPasswordInputVisible
                                            ? LucideIcons.eye
                                            : LucideIcons.eye_off,
                                        size: 20,
                                        color: const Color(0xFF6C757D),
                                      ),
                                      onPressed: () => setState(
                                        () => _isPasswordInputVisible =
                                            !_isPasswordInputVisible,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: const BorderSide(
                                        color: AppTheme.borderSide,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: const BorderSide(
                                        color: AppTheme.cancel,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: const BorderSide(
                                        color: AppTheme.cancel,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            Hero(
                              tag: 'auth_primary_button',
                              child: Material(
                                type: MaterialType.transparency,
                                child: ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => _submitRegistration(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size.fromHeight(56),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(36),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'Continue',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            SocialLoginWidget(
                              label: 'Sign up with Google',
                              onGoogleTap: () {
                                CustomToast.show(
                                  context,
                                  'Google Sign-In coming soon',
                                );
                              },
                            ),
                            const Spacer(),
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Already have an account?',
                                    style: TextStyle(
                                      color: AppTheme.tertiaryColor,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      unawaited(
                                        context.pushNamed(AuthRoutes.signin),
                                      );
                                    },
                                    child: const Text(
                                      'Sign in',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
