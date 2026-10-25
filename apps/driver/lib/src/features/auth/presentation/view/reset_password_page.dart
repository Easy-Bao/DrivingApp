import 'package:design_system/design_system.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/auth/presentation/bloc/reset_password/reset_password_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.resetPasswordBloc,
  });

  final String email;
  final ResetPasswordBloc resetPasswordBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ResetPasswordBloc>(
      create: (_) => resetPasswordBloc,
      child: _ResetPasswordContent(email: email),
    );
  }
}

class _ResetPasswordContent extends StatelessWidget {
  const _ResetPasswordContent({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
        listener: (context, state) {
          if (state is ResetPasswordSuccess) {
            TextInput.finishAutofillContext();
            context.goNamed(AuthRoutes.signin);
          }
        },
        builder: (context, state) => AppPasswordResetFlow(
          email: email,
          minimumPasswordLength: ResetPasswordBloc.minimumPasswordLength,
          isSubmitting: state is ResetPasswordLoading,
          isResending: state is ResetPasswordResending,
          errorMessage: state is ResetPasswordFailure
              ? state.errorMessage
              : null,
          onBack: () => context.pop(),
          onResend: () =>
              BlocProvider.of<ResetPasswordBloc>(context)
                  .add(ResetPasswordCodeRequested(email)),
          onSubmit: (code, password) =>
              BlocProvider.of<ResetPasswordBloc>(context).add(
                ResetPasswordSubmitted(
                  email: email,
                  code: code,
                  newPassword: password,
                ),
              ),
        ),
      );
}
