import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/signup/bloc/sign_up_bloc.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignUpBloc>(
      create: (context) => Modular.get<SignUpBloc>(),
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

  bool _isPasswordVisible = false;

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

  void _submitSignUp(BuildContext context) {
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
    BlocProvider.of<SignUpBloc>(context).add(
      SignUpEvent.submitted(
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
        child: BlocConsumer<SignUpBloc, SignUpState>(
          listener: (context, state) {
            state.maybeWhen(
              success: (_) {
                context.goNamed(HomeRoutes.home);
              },
              needsVerification: (email) {
                context.pushNamed(
                  AuthRoutes.verifyOtp,
                  extra: {
                    'email': email,
                    'password': _passengerPasswordController.text,
                  },
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
                          Center(
                            child: Column(
                              children: const [
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
                                  'Sign up to get started with EasyRide',
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
                            controller: _passengerNameController,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'John Doe',
                              errorText: _nameError,
                              prefixIcon: const Icon(LucideIcons.user),
                            ),
                            onChanged: (_) {
                              if (_nameError != null) {
                                setState(() {
                                  _nameError = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passengerPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              hintText: '0912 345 6789',
                              errorText: _phoneError,
                              prefixIcon: const Icon(LucideIcons.phone),
                            ),
                            onChanged: (_) {
                              if (_phoneError != null) {
                                setState(() {
                                  _phoneError = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passengerEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'name@example.com',
                              errorText: _emailError,
                              prefixIcon: const Icon(LucideIcons.mail),
                            ),
                            onChanged: (_) {
                              if (_emailError != null) {
                                setState(() {
                                  _emailError = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _passengerPasswordController,
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
                              if (_passwordError != null) {
                                setState(() {
                                  _passwordError = null;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 28),
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => _submitSignUp(context),
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
                                      'Sign Up',
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
                                'Already have an account? ',
                                style: TextStyle(
                                  color: AppTheme.tertiaryColor,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.pop(),
                                child: const Text(
                                  'Sign In',
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
