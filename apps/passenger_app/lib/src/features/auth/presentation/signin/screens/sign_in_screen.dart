import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/signin/bloc/sign_in_bloc.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
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
  bool _isChecked = false;

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

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
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
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'name@example.com',
                              errorText: _emailError,
                              prefixIcon: const Icon(LucideIcons.mail),
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
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: '••••••••',
                              errorText: _passwordError,
                              prefixIcon: const Icon(LucideIcons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? LucideIcons.eye
                                      : LucideIcons.eye_off,
                                  color: AppTheme.tertiaryColor,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
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
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _isChecked,
                                      activeColor: AppTheme.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (bool? value) {
                                        setState(() {
                                          _isChecked = value ?? false;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Remember me',
                                    style: TextStyle(
                                      color: AppTheme.tertiaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  unawaited(
                                    context.pushNamed(AuthRoutes.forgotPassword),
                                  );
                                },
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (serverErrorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.cancel.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.cancel.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.circle_alert,
                                    color: AppTheme.cancel,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      serverErrorMessage,
                                      style: const TextStyle(
                                        color: AppTheme.cancel,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => _submitSignIn(context),
                              child: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: AppTheme.tertiaryColor,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  unawaited(
                                    context.pushNamed(AuthRoutes.signup),
                                  );
                                },
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
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
