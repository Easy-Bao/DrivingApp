import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/auth/presentation/bloc/verify_otp/verify_otp_bloc.dart';
import 'package:passenger/src/features/home/home_routes.dart';

class const VerifyOtpPage({
  super.key,
  required this.email,
  required this.verifyOtpBloc,
  this.isForgotPassword = false,
}) extends StatelessWidget {
  final String email;
  final VerifyOtpBloc verifyOtpBloc;
  final bool isForgotPassword;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VerifyOtpBloc>(
      create: (_) => verifyOtpBloc..add(const VerifyOtpTimerStarted()),
      child: _VerifyOtpPageContent(
        email: email,
        isForgotPassword: isForgotPassword,
      ),
    );
  }
}

class const _VerifyOtpPageContent({
  required this.email,
  required this.isForgotPassword,
}) extends StatefulWidget {
  final String email;
  final bool isForgotPassword;

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
    BlocProvider.of<VerifyOtpBloc>(context)
        .add(VerifyOtpSubmitted(email: widget.email, code: code));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VerifyOtpBloc, VerifyOtpState>(
      listener: (context, state) {
        if (state is VerifyOtpSuccess) {
          if (widget.isForgotPassword) {
            unawaited(
              context.pushNamed(
                AuthRoutes.resetPasswordConfirm,
                extra: {'email': widget.email, 'code': _otpController.text},
              ),
            );
          } else {
            BlocProvider.of<SessionBloc>(context).add(const SessionStarted());
            context.goNamed(HomeRoutes.home);
          }
        } else if (state is VerifyOtpResent) {
          _otpController.clear();
        }
      },
      builder: (context, state) {
        final busy = state is VerifyOtpLoading || state is VerifyOtpResending;
        final error = state is VerifyOtpFailure
            ? state.errorMessage
            : state is VerifyOtpResendFailure
            ? state.errorMessage
            : null;
        final seconds = state is VerifyOtpTimerTicking
            ? state.secondsRemaining
            : 60;
        final canResend =
            state is VerifyOtpTimerExpired || state is VerifyOtpResendFailure;
        return AppAuthLayout(
          onBack: () => context.pop(),
          title: 'Check your email',
          description:
              'We sent a 6-digit verification code to ${widget.email}.',
          footer: FilledButton(
            onPressed: _otpController.text.length == 6 && !busy
                ? () => _triggerVerify(_otpController.text)
                : null,
            child: state is VerifyOtpLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: context.colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Verify code'),
          ),
          children: [
            AppVerificationCodeField(
              controller: _otpController,
              focusNode: _focusNode,
              enabled: !busy,
              autofocus: true,
              errorText: error,
              onSubmitted: (code) {
                if (code.length == 6 && !busy) {
                  _triggerVerify(code);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Didn’t get a code?',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: canResend && !busy
                      ? () => BlocProvider.of<VerifyOtpBloc>(context)
                            .add(VerifyOtpResendRequested(email: widget.email))
                      : null,
                  child: Text(
                    state is VerifyOtpResending
                        ? 'Sending…'
                        : canResend
                        ? 'Resend code'
                        : 'Resend in ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
