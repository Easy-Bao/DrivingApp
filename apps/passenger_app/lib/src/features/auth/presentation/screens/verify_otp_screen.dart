import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/verify_otp_cubit.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/verify_otp_state.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class VerifyOtpScreen extends StatelessWidget {
  final String email;
  final String password;
  final bool isForgotPassword;

  const VerifyOtpScreen({
    super.key,
    required this.email,
    this.password = '',
    this.isForgotPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VerifyOtpCubit>(
      create: (context) => Modular.get<VerifyOtpCubit>()..startResendTimer(),
      child: _VerifyOtpScreenContent(
        email: email,
        password: password,
        isForgotPassword: isForgotPassword,
      ),
    );
  }
}

class _VerifyOtpScreenContent extends StatefulWidget {
  final String email;
  final String password;
  final bool isForgotPassword;

  const _VerifyOtpScreenContent({
    required this.email,
    required this.password,
    required this.isForgotPassword,
  });

  @override
  State<_VerifyOtpScreenContent> createState() =>
      _VerifyOtpScreenContentState();
}

class _VerifyOtpScreenContentState extends State<_VerifyOtpScreenContent> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
    _otpController.addListener(_onOtpChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _focusNode.removeListener(_onFocusChanged);
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {});
  }

  void _onOtpChanged() {
    setState(() {});
    final text = _otpController.text;
    if (text.length == 6) {
      if (widget.isForgotPassword) {
        _navigateToResetPasswordConfirm(text);
      } else {
        _triggerVerify(text);
      }
    }
  }

  void _navigateToResetPasswordConfirm(String code) {
    FocusScope.of(context).unfocus();
    unawaited(
      context.pushNamed(
        AuthRoutes.resetPasswordConfirm,
        extra: {'email': widget.email, 'code': code},
      ),
    );
  }

  void _triggerVerify(String code) {
    FocusScope.of(context).unfocus();
    unawaited(
      BlocProvider.of<VerifyOtpCubit>(
        context,
      ).verifyOtp(
        email: widget.email,
        code: code,
        password: widget.password,
      ),
    );
  }

  void _onVerifySuccess() {
    CustomToast.show(context, 'Email verified successfully!');
    Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      if (Navigator.of(context).canPop()) {
        context.pop(true);
      } else {
        context.goNamed(HomeRoutes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = _otpController.text;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevron_left,
            color: AppTheme.primaryColor,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: BlocConsumer<VerifyOtpCubit, VerifyOtpState>(
        listener: (context, state) {
          if (state is VerifyOtpSuccess) {
            _onVerifySuccess();
          }
        },
        builder: (context, state) {
          final isLoading = state is VerifyOtpLoading;
          final errorMessage = state is VerifyOtpFailure
              ? state.errorMessage
              : null;

          int secondsRemaining = 60;
          bool canResend = false;

          if (state is VerifyOtpTimerTicking) {
            secondsRemaining = state.secondsRemaining;
          } else if (state is VerifyOtpTimerExpired) {
            canResend = true;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 40.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Text(
                  widget.isForgotPassword ? 'Verify Identity' : 'Verify Email',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.isForgotPassword
                      ? 'We sent a 6-digit code to ${widget.email}. Enter it to continue resetting your password.'
                      : 'We sent a 6-digit OTP to ${widget.email}. Please enter it below to verify your account.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppTheme.tertiaryColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                GestureDetector(
                  onTap: () {
                    _focusNode.requestFocus();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) {
                      String digit = '';
                      if (text.length > index) {
                        digit = text[index];
                      }
                      final isFocused =
                          text.length == index && _focusNode.hasFocus;

                      return Container(
                        width: 46,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isFocused
                                ? AppTheme.primaryColor
                                : (errorMessage != null
                                      ? AppTheme.cancel
                                      : AppTheme.borderSide),
                            width: isFocused ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          digit,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(-9999, 0),
                  child: SizedBox(
                    height: 1,
                    width: 1,
                    child: TextField(
                      controller: _otpController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      enableInteractiveSelection: false,
                      decoration: const InputDecoration(counterText: ''),
                    ),
                  ),
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Text(
                    errorMessage,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.cancel,
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: canResend
                      ? () => BlocProvider.of<VerifyOtpCubit>(
                          context,
                        ).startResendTimer()
                      : null,
                  child: Text(
                    canResend
                        ? 'Resend code'
                        : 'Resend code in ${secondsRemaining}s',
                    style: TextStyle(
                      color: canResend
                          ? AppTheme.primaryColor
                          : AppTheme.tertiaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (isLoading)
                  const CircularProgressIndicator(color: AppTheme.primaryColor)
                else
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: text.length == 6
                          ? () => widget.isForgotPassword
                                ? _navigateToResetPasswordConfirm(text)
                                : _triggerVerify(text)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.primaryColor
                            .withValues(alpha: 0.3),
                        disabledForegroundColor: Colors.white
                            .withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
