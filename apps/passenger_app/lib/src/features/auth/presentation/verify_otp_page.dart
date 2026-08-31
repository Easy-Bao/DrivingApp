import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/verify_otp/verify_otp_bloc.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:design_system/design_system.dart';

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
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface.withValues(alpha: 0),
        elevation: 0,
        leading: Center(
          child: IconButton(
            onPressed: () => context.pop(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(shape: const CircleBorder()),
            icon: Icon(
              LucideIcons.arrow_left,
              color: context.colorScheme.onSurface,
              size: 20,
            ),
          ),
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
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isForgotPassword
                        ? 'We sent a 6-digit code to ${widget.email}. Enter it to continue resetting your password.'
                        : 'We sent a 6-digit OTP to ${widget.email}. Please enter it below to verify your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.colorScheme.onSurfaceVariant,
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
                            color: context.colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isFocused
                                  ? context.colorScheme.onSurface
                                  : (errorMessage != null
                                        ? context.colorScheme.error
                                        : context.colorScheme.outlineVariant),
                              width: isFocused ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.colorScheme.onSurface.withValues(
                                  alpha: 0.03,
                                ),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            digit,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: context.colorScheme.onSurface,
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
                      style: TextStyle(
                        color: context.colorScheme.error,
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
                            backgroundColor: context.colorScheme.onSurface,
                            foregroundColor: context.colorScheme.onPrimary,
                            disabledBackgroundColor: context
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.3),
                            disabledForegroundColor: context.colorScheme.surface
                                .withValues(alpha: 0.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(36),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: context.colorScheme.surface,
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
                      Text(
                        "Didn't get a code?",
                        style: TextStyle(
                          color: context.colorScheme.onSurfaceVariant,
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
                                ? context.colorScheme.onSurface
                                : context.colorScheme.onSurfaceVariant,
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
