import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/verify_otp_cubit.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/verify_otp_state.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class VerifyOtpScreen extends StatelessWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VerifyOtpCubit>(
      create: (context) => Modular.get<VerifyOtpCubit>()..startResendTimer(),
      child: _VerifyOtpScreenContent(email: email),
    );
  }
}

class _VerifyOtpScreenContent extends StatefulWidget {
  final String email;

  const _VerifyOtpScreenContent({required this.email});

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
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    final text = _otpController.text;
    if (text.length == 6) {
      _triggerVerify(text);
    }
  }

  void _triggerVerify(String code) {
    FocusScope.of(context).unfocus();
    unawaited(
      BlocProvider.of<VerifyOtpCubit>(context).verifyOtp(
        email: widget.email,
        code: code,
      ),
    );
  }

  void _showSuccessModal() {
    unawaited(
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          return AlertDialog(
            backgroundColor: AppTheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppTheme.complete,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.check,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Verification Successful!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Logging in shortly...',
                  style: TextStyle(fontSize: 13, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );

    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      Navigator.of(context).pop();
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
        leadingWidth: 100,
        leading: TextButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(
            LucideIcons.chevron_left,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          label: const Text(
            'Back',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      body: BlocConsumer<VerifyOtpCubit, VerifyOtpState>(
        listener: (context, state) {
          if (state is VerifyOtpSuccess) {
            _showSuccessModal();
          }
        },
        builder: (context, state) {
          final isLoading = state is VerifyOtpLoading;
          final errorMessage =
              state is VerifyOtpFailure ? state.errorMessage : null;

          int secondsRemaining = 60;
          bool canResend = false;

          if (state is VerifyOtpTimerTicking) {
            secondsRemaining = state.secondsRemaining;
          } else if (state is VerifyOtpTimerExpired) {
            canResend = true;
          }

          return SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Verify Email',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'We sent a 6-digit OTP to ${widget.email}. Please enter it below to verify your account.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF6B7280),
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
                        width: 44,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFocused
                                ? AppTheme.primaryColor
                                : (errorMessage != null
                                    ? AppTheme.cancel
                                    : AppTheme.primaryColor
                                        .withValues(alpha: 0.16)),
                            width: isFocused ? 2 : 1,
                          ),
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
                Opacity(
                  opacity: 0,
                  child: SizedBox(
                    height: 0,
                    width: 0,
                    child: TextField(
                      controller: _otpController,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofocus: true,
                      decoration: const InputDecoration(
                        counterText: '',
                      ),
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
                      ? () =>
                          BlocProvider.of<VerifyOtpCubit>(context).startResendTimer()
                      : null,
                  child: Text(
                    canResend
                        ? 'Resend code'
                        : 'Resend code in ${secondsRemaining}s',
                    style: TextStyle(
                      color: canResend
                          ? AppTheme.primaryColor
                          : AppTheme.primaryColor.withValues(alpha: 0.4),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (isLoading)
                  const CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed:
                          text.length == 6 ? () => _triggerVerify(text) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.neutralColor,
                        disabledBackgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.5),
                        disabledForegroundColor:
                            AppTheme.neutralColor.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
