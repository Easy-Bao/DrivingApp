import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/forgot_password_cubit.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/forgot_password_state.dart';
import 'package:shared_ui/shared_ui.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForgotPasswordCubit>(
      create: (context) => Modular.get<ForgotPasswordCubit>(),
      child: const _ForgotPasswordScreenContent(),
    );
  }
}

class _ForgotPasswordScreenContent extends StatefulWidget {
  const _ForgotPasswordScreenContent();

  @override
  State<_ForgotPasswordScreenContent> createState() =>
      _ForgotPasswordScreenContentState();
}

class _ForgotPasswordScreenContentState
    extends State<_ForgotPasswordScreenContent> {
  final TextEditingController _emailController = TextEditingController();
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitResetLink(BuildContext context) {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();

    setState(() {
      if (email.isEmpty) {
        _emailError = 'Please enter your email';
      } else if (!email.contains('@')) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }
    });

    if (_emailError != null) {
      return;
    }

    unawaited(
      BlocProvider.of<ForgotPasswordCubit>(context).sendResetLink(email),
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
      body: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordSuccess) {
            CustomToast.show(
              context,
              'Password reset OTP code sent to your email.',
            );
            unawaited(
              context.pushNamed(
                AuthRoutes.verifyOtp,
                extra: {
                  'email': _emailController.text,
                  'isForgotPassword': true,
                },
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ForgotPasswordLoading;
          final errorMessage = state is ForgotPasswordFailure
              ? state.errorMessage
              : null;

          final effectiveEmailError = _emailError ?? errorMessage;

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                "No worries, we'll send you reset instructions. Please enter the email address linked to your account.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: AppTheme.tertiaryColor,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 40),
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
                              TextField(
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                controller: _emailController,
                                textInputAction: TextInputAction.done,
                                onChanged: (_) {
                                  if (_emailError != null) {
                                    setState(() => _emailError = null);
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
                                    child: Icon(LucideIcons.mail, size: 20, color: Color(0xFF495057)),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(36),
                                    borderSide: const BorderSide(color: AppTheme.borderSide),
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
                                    borderSide: const BorderSide(color: AppTheme.cancel, width: 1.0),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(36),
                                    borderSide: const BorderSide(color: AppTheme.cancel, width: 1.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: isLoading
                                  ? null
                                  : () => _submitResetLink(context),
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
                                      'Reset Password',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => context.pop(),
                              icon: const Icon(
                                LucideIcons.arrow_left,
                                size: 16,
                                color: AppTheme.primaryColor,
                              ),
                              label: const Text(
                                'Back to Sign In',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
