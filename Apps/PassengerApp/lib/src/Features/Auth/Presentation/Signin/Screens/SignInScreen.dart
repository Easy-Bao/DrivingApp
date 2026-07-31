import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/Features/Auth/AuthRoutes.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/Signin/Bloc/SignInBloc.dart';
import 'package:passenger_app/src/Features/Home/HomeRoutes.dart';
import 'package:shared_ui/shared_ui.dart';

class SigninScreen extends StatelessWidget {
  const SigninScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInBloc>(
      create: (context) => Modular.get<SignInBloc>(),
      child: const _SigninScreenContent(),
    );
  }
}

class _SigninScreenContent extends StatefulWidget {
  const _SigninScreenContent();

  @override
  State<_SigninScreenContent> createState() => _SigninScreenContentState();
}

class _SigninScreenContentState extends State<_SigninScreenContent> {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool isChecked = false;

  String? _emailError;
  String? _passwordError;
  bool _isServerErrorCleared = false;
  Timer? _validationErrorTimer;

  @override
  void dispose() {
    _validationErrorTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startErrorAutoDismissTimer() {
    _validationErrorTimer?.cancel();
    _validationErrorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _emailError = null;
          _passwordError = null;
          _isServerErrorCleared = true;
        });
      }
    });
  }

  void _submitSignIn(BuildContext context) {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isServerErrorCleared = false;
      if (email.isEmpty) {
        _emailError = 'Please enter your email';
      } else if (!_emailRegex.hasMatch(email)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }

      _passwordError = password.isEmpty ? 'Please enter your password' : null;
    });

    if (_emailError != null || _passwordError != null) {
      _startErrorAutoDismissTimer();
      return;
    }

    BlocProvider.of<SignInBloc>(context).add(
      SignInEvent.submitted(email: email, password: password),
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
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Image.asset(
          'assets/logo/applogo.png',
          package: 'shared_ui',
          height: 150,
          fit: BoxFit.cover,
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<SignInBloc, SignInState>(
          listener: (context, state) {
            state.maybeWhen(
              success: (_) {
                context.goNamed(HomeRoutes.home);
              },
              needsVerification: (email) {
                unawaited(
                  context.pushNamed(
                    AuthRoutes.verifyOtp,
                    extra: {'email': email},
                  ),
                );
              },
              failure: (message) {
                CustomToast.show(context, message);
              },
              orElse: () {},
            );
          },
          builder: (context, state) {
            final isLoading = state.maybeWhen(
              loading: () => true,
              orElse: () => false,
            );
            final serverErrorMessage = state.maybeWhen(
              failure: (message) => _isServerErrorCleared ? null : message,
              orElse: () => null,
            );

            final effectiveEmailError = _emailError ?? serverErrorMessage;
            final effectivePasswordError = _passwordError;

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          const Center(
                            child: Column(
                              children: [
                                Text(
                                  'Sign in to EasyRide',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Enter your credentials to continue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppTheme.tertiaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
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
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                onChanged: (_) {
                                  if (_emailError != null ||
                                      _isServerErrorCleared == false) {
                                    setState(() {
                                      _emailError = null;
                                      _isServerErrorCleared = true;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                  errorText: effectiveEmailError,
                                  errorStyle: const TextStyle(
                                    color: AppTheme.cancel,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                          const SizedBox(height: 20),
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
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submitSignIn(context),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                onChanged: (_) {
                                  if (_passwordError != null ||
                                      _isServerErrorCleared == false) {
                                    setState(() {
                                      _passwordError = null;
                                      _isServerErrorCleared = true;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  errorText: effectivePasswordError,
                                  errorStyle: const TextStyle(
                                    color: AppTheme.cancel,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                      _isPasswordVisible
                                          ? LucideIcons.eye
                                          : LucideIcons.eye_off,
                                      size: 20,
                                      color: const Color(0xFF6C757D),
                                    ),
                                    onPressed: () => setState(
                                      () => _isPasswordVisible =
                                          !_isPasswordVisible,
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
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: isChecked,
                                    activeColor: AppTheme.primaryColor,
                                    onChanged: (bool? val) {
                                      setState(() {
                                        isChecked = val ?? false;
                                      });
                                    },
                                  ),
                                  const Text(
                                    'Remember me',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.tertiaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  unawaited(
                                    context.pushNamed(
                                      AuthRoutes.forgotPassword,
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Hero(
                            tag: 'auth_primary_button',
                            child: Material(
                              type: MaterialType.transparency,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => _submitSignIn(context),
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
                                        'Sign In',
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
                                  "Don't have an account?",
                                  style: TextStyle(
                                    color: AppTheme.tertiaryColor,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    unawaited(
                                      context.pushNamed(AuthRoutes.signup),
                                    );
                                  },
                                  child: const Text(
                                    'Sign up',
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}
