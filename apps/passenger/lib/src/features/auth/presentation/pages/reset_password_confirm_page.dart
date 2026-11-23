import 'package:design_system/design_system.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/auth/presentation/bloc/reset_password_confirm/reset_password_confirm_bloc.dart';
import 'package:passenger/src/features/auth/presentation/validation/auth_form_validator.dart';

class const ResetPasswordConfirmPage({
  super.key,
  required this.email,
  required this.code,
  required this.resetPasswordConfirmBloc,
}) extends StatelessWidget {
  final String email;
  final String code;
  final ResetPasswordConfirmBloc resetPasswordConfirmBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ResetPasswordConfirmBloc>(
      create: (_) => resetPasswordConfirmBloc,
      child: _ResetPasswordConfirmPageContent(email: email, code: code),
    );
  }
}

class const _ResetPasswordConfirmPageContent({
  required this.email,
  required this.code,
}) extends StatelessWidget {
  final String email;
  final String code;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ResetPasswordConfirmBloc, ResetPasswordConfirmState>(
        listener: (context, state) {
          if (state is ResetPasswordConfirmSuccess) {
            TextInput.finishAutofillContext();
            context.goNamed(AuthRoutes.signin);
          }
        },
        builder: (context, state) => AppPasswordResetFlow(
          email: email,
          initialCode: code,
          minimumPasswordLength: AuthFormValidator.minimumPasswordLength,
          isVerifyingCode: state is ResetPasswordCodeVerifying,
          isCodeVerified:
              state is ResetPasswordCodeVerified ||
              state is ResetPasswordConfirmLoading ||
              state is ResetPasswordConfirmFailure ||
              code.trim().length == 6,
          isSubmitting: state is ResetPasswordConfirmLoading,
          isResending: state is ResetPasswordCodeResending,
          errorMessage: switch (state) {
            ResetPasswordCodeVerificationFailure(:final errorMessage) ||
            ResetPasswordConfirmFailure(:final errorMessage) => errorMessage,
            _ => null,
          },
          onBack: () => context.pop(),
          onVerifyCode: (enteredCode) =>
              BlocProvider.of<ResetPasswordConfirmBloc>(context).add(
                ResetPasswordCodeVerifyRequested(
                  email: email,
                  code: enteredCode,
                ),
              ),
          onCodeChanged: () =>
              BlocProvider.of<ResetPasswordConfirmBloc>(context)
                  .add(const ResetPasswordCodeVerificationReset()),
          onStepBack: () =>
              BlocProvider.of<ResetPasswordConfirmBloc>(context)
                  .add(const ResetPasswordCodeVerificationReset()),
          onResend: () =>
              BlocProvider.of<ResetPasswordConfirmBloc>(context)
                  .add(ResetPasswordCodeRequested(email)),
          onSubmit: (code, password) =>
              BlocProvider.of<ResetPasswordConfirmBloc>(context).add(
                ResetPasswordConfirmSubmitted(
                  email: email,
                  code: code,
                  newPassword: password,
                ),
              ),
        ),
      );
}
