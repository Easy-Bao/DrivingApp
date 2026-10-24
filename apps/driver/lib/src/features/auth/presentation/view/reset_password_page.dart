import 'package:design_system/design_system.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/auth/presentation/view/widgets/driver_auth_layout.dart';
import 'package:driver/src/features/auth/presentation/bloc/reset_password/reset_password_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
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

class _ResetPasswordContent extends StatefulWidget {
  const _ResetPasswordContent({required this.email});

  final String email;

  @override
  State<_ResetPasswordContent> createState() => _ResetPasswordContentState();
}

class _ResetPasswordContentState extends State<_ResetPasswordContent> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (BlocProvider.of<ResetPasswordBloc>(context).state
        is ResetPasswordLoading) {
      return;
    }
    FocusScope.of(context).unfocus();
    BlocProvider.of<ResetPasswordBloc>(context).add(
      ResetPasswordSubmitted(
        email: widget.email,
        code: _codeController.text,
        newPassword: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
      listener: (context, state) {
        if (state is ResetPasswordSuccess) {
          TextInput.finishAutofillContext();
          context.goNamed(AuthRoutes.signin);
        }
      },
      builder: (context, state) {
        final isLoading = state is ResetPasswordLoading;
        return DriverAuthLayout(
          onBack: () => context.pop(),
          title: 'Reset password',
          description:
              'Enter the code sent to ${widget.email} and choose a new password.',
          footer: FilledButton(
            onPressed: isLoading ? null : () => _submit(context),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: context.colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Reset password'),
          ),
          children: [
            if (state is ResetPasswordFailure) ...[
              AppErrorBanner(
                message: state.errorMessage,
                onRetry: () => _submit(context),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Verification code',
                    style: context.textStyles.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    enabled: !isLoading,
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    autocorrect: false,
                    decoration: const InputDecoration(
                      hintText: 'Enter verification code',
                      prefixIcon: Icon(LucideIcons.shield_check, size: 18),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('New password', style: context.textStyles.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    enabled: !isLoading,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => _submit(context),
                    decoration: InputDecoration(
                      hintText: 'Enter a new password',
                      helperText:
                          'Use at least ${ResetPasswordBloc.minimumPasswordLength} characters.',
                      helperMaxLines: 2,
                      prefixIcon: const Icon(LucideIcons.lock, size: 18),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: isLoading
                            ? null
                            : () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                        icon: Icon(
                          _obscurePassword
                              ? LucideIcons.eye_off
                              : LucideIcons.eye,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
