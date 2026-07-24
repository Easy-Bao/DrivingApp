import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/reset_password_confirm_cubit.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/reset_password_confirm_state.dart';
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
    return BlocProvider<ResetPasswordConfirmCubit>(
      create: (context) => Modular.get<ResetPasswordConfirmCubit>(),
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
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitNewPassword(BuildContext context) {
    FocusScope.of(context).unfocus();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.length < 8) {
      CustomToast.show(
        context,
        'New password must be at least 8 characters long.',
      );
      return;
    }
    if (newPassword != confirmPassword) {
      CustomToast.show(context, 'Passwords do not match.');
      return;
    }

    unawaited(
      BlocProvider.of<ResetPasswordConfirmCubit>(context).confirmPasswordReset(
        email: widget.email,
        code: widget.code,
        newPassword: newPassword,
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
      body: BlocConsumer<ResetPasswordConfirmCubit, ResetPasswordConfirmState>(
        listener: (context, state) {
          if (state is ResetPasswordConfirmSuccess) {
            CustomToast.show(
              context,
              'Password reset successful! Please sign in.',
            );
            context.goNamed(AuthRoutes.signin);
          } else if (state is ResetPasswordConfirmFailure) {
            CustomToast.show(context, state.errorMessage);
          }
        },
        builder: (context, state) {
          final isLoading = state is ResetPasswordConfirmLoading;

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
                                'Set New Password',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Your identity has been verified. Enter your new password below.',
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
                                  'NEW PASSWORD',
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
                                controller: _newPasswordController,
                                obscureText: _obscureNewPassword,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'At least 8 characters',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Icon(LucideIcons.lock, size: 20, color: Color(0xFF495057)),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureNewPassword
                                          ? LucideIcons.eye_off
                                          : LucideIcons.eye,
                                      size: 20,
                                      color: const Color(0xFF6C757D),
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureNewPassword =
                                          !_obscureNewPassword,
                                    ),
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
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'CONFIRM PASSWORD',
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
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submitNewPassword(context),
                                style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Re-enter your password',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Icon(LucideIcons.lock, size: 20, color: Color(0xFF495057)),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? LucideIcons.eye_off
                                          : LucideIcons.eye,
                                      size: 20,
                                      color: const Color(0xFF6C757D),
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    ),
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
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () => _submitNewPassword(context),
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
                                  'Save New Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
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
    );
  }
}
