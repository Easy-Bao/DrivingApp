import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/verify_otp/bloc/verify_otp_bloc.dart';
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
    return BlocProvider<VerifyOtpBloc>(
      create: (context) => Modular.get<VerifyOtpBloc>()
        ..add(const VerifyOtpEvent.timerStarted()),
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
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  String? _otpError;

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _submitOtp(BuildContext context) {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() {
        _otpError = 'Please enter all 6 digits.';
      });
      return;
    }

    setState(() {
      _otpError = null;
    });

    BlocProvider.of<VerifyOtpBloc>(context).add(
      VerifyOtpEvent.submitted(
        email: widget.email,
        code: code,
        password: widget.password,
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
        child: BlocConsumer<VerifyOtpBloc, VerifyOtpState>(
          listener: (context, state) {
            state.maybeWhen(
              success: () {
                if (widget.isForgotPassword) {
                  final code = _controllers.map((c) => c.text).join();
                  unawaited(
                    context.pushNamed(
                      AuthRoutes.resetPasswordConfirm,
                      extra: {
                        'email': widget.email,
                        'code': code,
                      },
                    ),
                  );
                } else {
                  context.goNamed(HomeRoutes.home);
                }
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

            final secondsRemaining = state.maybeWhen(
              timerTicking: (s) => s,
              orElse: () => 0,
            );

            final isTimerExpired = state.maybeWhen(
              timerExpired: () => true,
              orElse: () => false,
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Verify Email',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a 6-digit verification code to ${widget.email}. Enter code below.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.tertiaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      6,
                      (index) => SizedBox(
                        width: 45,
                        height: 55,
                        child: TextField(
                          controller: _controllers[index],
                          focusNode: _focusNodes[index],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: _otpError != null
                                    ? AppTheme.cancel
                                    : AppTheme.borderSide,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && index < 5) {
                              _focusNodes[index + 1].requestFocus();
                            } else if (value.isEmpty && index > 0) {
                              _focusNodes[index - 1].requestFocus();
                            }
                            if (_controllers
                                .every((c) => c.text.isNotEmpty)) {
                              _submitOtp(context);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  if (_otpError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _otpError!,
                      style: const TextStyle(
                        color: AppTheme.cancel,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => _submitOtp(context),
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
                              'Verify Code',
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
                      Text(
                        isTimerExpired
                            ? "Didn't receive code? "
                            : 'Resend code in ${secondsRemaining}s',
                        style: const TextStyle(
                          color: AppTheme.tertiaryColor,
                        ),
                      ),
                      if (isTimerExpired)
                        GestureDetector(
                          onTap: () {
                            BlocProvider.of<VerifyOtpBloc>(context).add(
                              const VerifyOtpEvent.timerStarted(),
                            );
                          },
                          child: const Text(
                            'Resend Code',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
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
