import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/auth/bloc/verify_otp/verify_otp_bloc.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/shared/widgets/app_back_button_widget.dart';

class VerifyOtpPage extends StatelessWidget {
  final String email;
  final bool isForgotPassword;

  const VerifyOtpPage({
    super.key,
    required this.email,
    this.isForgotPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VerifyOtpBloc>(
      create: (context) =>
          Modular.get<VerifyOtpBloc>()..add(const VerifyOtpTimerStarted()),
      child: _VerifyOtpPageContent(
        email: email,
        isForgotPassword: isForgotPassword,
      ),
    );
  }
}

class _VerifyOtpPageContent extends StatefulWidget {
  final String email;
  final bool isForgotPassword;

  const _VerifyOtpPageContent({
    required this.email,
    required this.isForgotPassword,
  });

  @override
  State<_VerifyOtpPageContent> createState() => _VerifyOtpPageContentState();
}

class _VerifyOtpPageContentState extends State<_VerifyOtpPageContent> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
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
    setState(() {});
  }

  void _triggerVerify(String code) {
    FocusScope.of(context).unfocus();
    if (widget.isForgotPassword) {
      unawaited(
        context.pushNamed(
          AuthRoutes.resetPasswordConfirm,
          extra: {'email': widget.email, 'code': code},
        ),
      );
    } else {
      BlocProvider.of<VerifyOtpBloc>(
        context,
      ).add(VerifyOtpSubmitted(email: widget.email, code: code));
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = _otpController.text;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Center(
          child: AppBackButtonWidget(onPressed: () => context.pop()),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<VerifyOtpBloc, VerifyOtpState>(
          listener: (context, state) {
            if (state is VerifyOtpSuccess) {
              if (widget.isForgotPassword) {
                unawaited(
                  context.pushNamed(
                    AuthRoutes.resetPasswordConfirm,
                    extra: {'email': widget.email, 'code': text},
                  ),
                );
              } else {
                BlocProvider.of<SessionBloc>(
                  context,
                ).add(const SessionStarted());
                context.goNamed(HomeRoutes.home);
              }
            } else if (state is VerifyOtpResent) {
              _otpController.clear();
            }
          },
          builder: (context, state) {
            final isLoading = state is VerifyOtpLoading;
            final isResending = state is VerifyOtpResending;
            final errorMessage = state is VerifyOtpFailure
                ? state.errorMessage
                : state is VerifyOtpResendFailure
                ? state.errorMessage
                : null;
            final secondsRemaining = state is VerifyOtpTimerTicking
                ? state.secondsRemaining
                : 60;
            final isTimerExpired =
                state is VerifyOtpTimerExpired ||
                state is VerifyOtpResendFailure;

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
                    widget.isForgotPassword
                        ? 'Verify Identity'
                        : 'Verify Email',
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
                  const SizedBox(height: 32),
                  Hero(
                    tag: 'auth_primary_button',
                    child: Material(
                      type: MaterialType.transparency,
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (text.length == 6 && !isLoading)
                              ? () => _triggerVerify(text)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppTheme.primaryColor
                                .withValues(alpha: 0.3),
                            disabledForegroundColor: Colors.white.withValues(
                              alpha: 0.5,
                            ),
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
                                  'Verify',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      const Text(
                        "Didn't get a code?",
                        style: TextStyle(
                          color: AppTheme.tertiaryColor,
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: isTimerExpired && !isResending
                            ? () => BlocProvider.of<VerifyOtpBloc>(context).add(
                                VerifyOtpResendRequested(email: widget.email),
                              )
                            : null,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          isResending
                              ? 'Sending...'
                              : isTimerExpired
                              ? 'Resend'
                              : 'Resend in ${secondsRemaining}s',
                          style: TextStyle(
                            color: isTimerExpired && !isResending
                                ? AppTheme.primaryColor
                                : AppTheme.tertiaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
