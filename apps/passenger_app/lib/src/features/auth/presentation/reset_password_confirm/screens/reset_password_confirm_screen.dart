import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/reset_password_confirm/bloc/reset_password_confirm_bloc.dart';
import 'package:shared_ui/shared_ui.dart';

class ResetPasswordConfirmScreen extends StatelessWidget {
  final String email;
  final String code;

  const ResetPasswordConfirmScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ResetPasswordConfirmBloc>(
      create: (context) => Modular.get<ResetPasswordConfirmBloc>(),
      child: _ResetPasswordConfirmScreenContent(email: email, code: code),
    );
  }
}

class _ResetPasswordConfirmScreenContent extends StatefulWidget {
  final String email;
  final String code;

  const _ResetPasswordConfirmScreenContent({
    required this.email,
    required this.code,
  });

  @override
  State<_ResetPasswordConfirmScreenContent> createState() =>
      _ResetPasswordConfirmScreenContentState();
}

class _ResetPasswordConfirmScreenContentState
    extends State<_ResetPasswordConfirmScreenContent> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  String? _passwordError;
  String? _confirmPasswordError;
  Timer? _validationErrorTimer;

  @override
  void dispose() {
    _validationErrorTimer?.cancel();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startErrorAutoDismissTimer() {
    _validationErrorTimer?.cancel();
    _validationErrorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _passwordError = null;
          _confirmPasswordError = null;
        });
      }
    });
  }

  void _submitNewPassword(BuildContext context) {
    FocusScope.of(context).unfocus();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      if (password.length < 8) {
        _passwordError = 'Password must be at least 8 characters long.';
      } else {
        _passwordError = null;
      }

      if (confirmPassword != password) {
        _confirmPasswordError = 'Passwords do not match.';
      } else {
        _confirmPasswordError = null;
      }
    });

    if (_passwordError != null || _confirmPasswordError != null) {
      _startErrorAutoDismissTimer();
      return;
    }

    BlocProvider.of<ResetPasswordConfirmBloc>(context).add(
      ResetPasswordConfirmEvent.submitted(
        email: widget.email,
        code: widget.code,
        newPassword: password,
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
      ),
      body: SafeArea(
        child: BlocConsumer<ResetPasswordConfirmBloc, ResetPasswordConfirmState>(
          listener: (context, state) {
            state.maybeWhen(
              success: () {
                CustomToast.show(
                  context,
                  'Password successfully reset. Please sign in with your new password.',
                );
                context.goNamed(AuthRoutes.signin);
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

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Create New Password',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your new password below to update your credentials.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.tertiaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'New Password',
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
                  const SizedBox(height: 20),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      hintText: '••••••••',
                      errorText: _confirmPasswordError,
                      prefixIcon: const Icon(LucideIcons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? LucideIcons.eye
                              : LucideIcons.eye_off,
                          color: AppTheme.tertiaryColor,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                    onChanged: (_) {
                      if (_confirmPasswordError != null) {
                        setState(() {
                          _confirmPasswordError = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => _submitNewPassword(context),
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
                              'Reset Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
