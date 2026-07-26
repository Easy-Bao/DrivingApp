import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/signup_cubit.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/signup_state.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignUpCubit>(
      create: (context) => Modular.get<SignUpCubit>(),
      child: const _SignupScreenContent(),
    );
  }
}

class _SignupScreenContent extends StatefulWidget {
  const _SignupScreenContent();

  @override
  State<_SignupScreenContent> createState() => _SignupScreenContentState();
}

class _SignupScreenContentState extends State<_SignupScreenContent> {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

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
  Timer? _validationErrorTimer;

  @override
  void dispose() {
    _validationErrorTimer?.cancel();
    _passengerNameController.dispose();
    _passengerPhoneController.dispose();
    _passengerEmailController.dispose();
    _passengerPasswordController.dispose();
    super.dispose();
  }

  void _startErrorAutoDismissTimer() {
    _validationErrorTimer?.cancel();
    _validationErrorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _nameError = null;
          _phoneError = null;
          _emailError = null;
          _passwordError = null;
        });
      }
    });
  }

  void _submitRegistration(BuildContext context) {
    FocusScope.of(context).unfocus();
    final name = _passengerNameController.text.trim();
    final rawPhone = _passengerPhoneController.text.trim();
    final email = _passengerEmailController.text.trim();
    final password = _passengerPasswordController.text;

    setState(() {
      _nameError = name.isEmpty ? 'Please enter your name' : null;
      if (rawPhone.isEmpty) {
        _phoneError = 'Please enter your phone number';
      } else if (!validatePhPhoneNumber(rawPhone)) {
        _phoneError = 'Enter a valid number';
      } else {
        _phoneError = null;
      }

      if (email.isEmpty) {
        _emailError = 'Please enter your email';
      } else if (!_emailRegex.hasMatch(email)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }
      _passwordError = password.isEmpty ? 'Please enter your password' : null;
    });

    if (_nameError != null ||
        _phoneError != null ||
        _emailError != null ||
        _passwordError != null) {
      _startErrorAutoDismissTimer();
      return;
    }

    final formattedPhone = normalizePhPhoneNumber(rawPhone);
    unawaited(
      BlocProvider.of<SignUpCubit>(context).registerPassenger(
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
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
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
        child: BlocConsumer<SignUpCubit, SignUpState>(
          listener: (context, state) {
            if (state is SignUpNeedsVerification) {
              unawaited(() async {
                final verified = await context.pushNamed<bool>(
                  AuthRoutes.verifyOtp,
                  extra: {
                    'email': state.email,
                    'password': _passengerPasswordController.text,
                  },
                );
                if (verified == true && context.mounted) {
                  context.goNamed(HomeRoutes.home);
                }
              }());
            } else if (state is SignUpSuccess) {
              context.goNamed(HomeRoutes.home);
            }
          },
          builder: (context, state) {
            final isLoading = state is SignUpLoading;
            final errorMessage = state is SignUpFailure
                ? state.errorMessage
                : null;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 550),
                child: CustomScrollView(
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
                            const Text(
                              'Create Account',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                                letterSpacing: -1.0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter your details to create your account and get started.',
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.tertiaryColor,
                                fontWeight: FontWeight.w400,
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
                            TextField(
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              controller: _passengerNameController,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                setState(() => _nameError = null);
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
                                    width: 1.0,
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
                            TextField(
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              controller: _passengerPhoneController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.next,
                              inputFormatters: [PhPhoneTextInputFormatter()],
                              onChanged: (_) {
                                setState(() => _phoneError = null);
                              },
                              decoration: InputDecoration(
                                hintText: '9XX XXX XXXX',
                                errorText: _phoneError,
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(left: 14, right: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(
                                        LucideIcons.phone,
                                        size: 18,
                                        color: Color(0xFF495057),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        '+63',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        '|',
                                        style: TextStyle(
                                          color: Color(0xFFCED4DA),
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(),
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
                                    width: 1.0,
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
                            TextField(
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              controller: _passengerEmailController,
                              textInputAction: TextInputAction.next,
                              onChanged: (_) {
                                setState(() => _emailError = null);
                              },
                              decoration: InputDecoration(
                                hintText: 'Email address',
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
                                    width: 1.0,
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
                            TextField(
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              obscureText: !_isPasswordInputVisible,
                              controller: _passengerPasswordController,
                              textInputAction: TextInputAction.done,
                              onChanged: (_) {
                                setState(() => _passwordError = null);
                              },
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
                                    width: 1.0,
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
