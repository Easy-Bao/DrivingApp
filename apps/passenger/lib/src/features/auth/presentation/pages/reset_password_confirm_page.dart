import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
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
}) extends StatefulWidget {
  final String email;
  final String code;

  @override
  State<_ResetPasswordConfirmPageContent> createState() =>
      _ResetPasswordConfirmPageContentState();
}

class _ResetPasswordConfirmPageContentState
    extends State<_ResetPasswordConfirmPageContent> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  late final TextEditingController _codeController;
  String? _codeError;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.code);
  }

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _newPasswordError;
  String? _confirmPasswordError;
  String? _submissionError;

  @override
  void dispose() {
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitNewPassword(BuildContext context) {
    if (BlocProvider.of<ResetPasswordConfirmBloc>(context).state
        is ResetPasswordConfirmLoading) {
      return;
    }
    FocusScope.of(context).unfocus();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _codeError = _codeController.text.trim().isEmpty
          ? 'Enter the verification code.'
          : null;
      _submissionError = null;
      _newPasswordError = authFormValidator.password(newPassword);
      _confirmPasswordError = authFormValidator.confirmation(
        newPassword,
        confirmPassword,
      );
    });

    if (_codeError != null ||
        _newPasswordError != null ||
        _confirmPasswordError != null) {
      return;
    }

    BlocProvider.of<ResetPasswordConfirmBloc>(context).add(
      ResetPasswordConfirmSubmitted(
        email: widget.email,
        code: _codeController.text.trim(),
        newPassword: newPassword,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ResetPasswordConfirmBloc, ResetPasswordConfirmState>(
      listener: (context, state) {
        if (state is ResetPasswordConfirmSuccess) {
          TextInput.finishAutofillContext();
          context.goNamed(AuthRoutes.signin);
        } else if (state is ResetPasswordConfirmFailure) {
          setState(() => _submissionError = state.errorMessage);
        }
      },
      builder: (context, state) {
        final isLoading = state is ResetPasswordConfirmLoading;
        return AppAuthLayout(
          onBack: () => context.pop(),
          title: 'Reset password',
          description:
              'Enter the code sent to ${widget.email} and choose a new password.',
          footer: FilledButton(
            onPressed: isLoading ? null : () => _submitNewPassword(context),
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
            if (_submissionError != null) ...[
              AppErrorBanner(
                message: _submissionError!,
                onRetry: () => _submitNewPassword(context),
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
                    onChanged: (_) => setState(() {
                      _codeError = null;
                      _submissionError = null;
                    }),
                    decoration: InputDecoration(
                      hintText: 'Enter verification code',
                      errorText: _codeError,
                      prefixIcon: const Icon(
                        LucideIcons.shield_check,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('New password', style: context.textStyles.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    enabled: !isLoading,
                    controller: _newPasswordController,
                    obscureText: _obscureNewPassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    autocorrect: false,
                    enableSuggestions: false,
                    onChanged: (_) => setState(() {
                      _newPasswordError = null;
                      _submissionError = null;
                    }),
                    decoration: InputDecoration(
                      hintText: 'Enter a new password',
                      errorText: _newPasswordError,
                      helperText: 'Use at least 8 characters.',
                      helperMaxLines: 2,
                      prefixIcon: const Icon(LucideIcons.lock, size: 18),
                      suffixIcon: IconButton(
                        tooltip: _obscureNewPassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: isLoading
                            ? null
                            : () => setState(
                                () =>
                                    _obscureNewPassword = !_obscureNewPassword,
                              ),
                        icon: Icon(
                          _obscureNewPassword
                              ? LucideIcons.eye_off
                              : LucideIcons.eye,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Confirm password',
                    style: context.textStyles.labelMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    enabled: !isLoading,
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => _submitNewPassword(context),
                    onChanged: (_) => setState(() {
                      _confirmPasswordError = null;
                      _submissionError = null;
                    }),
                    decoration: InputDecoration(
                      hintText: 'Re-enter your password',
                      errorText: _confirmPasswordError,
                      prefixIcon: const Icon(LucideIcons.lock, size: 18),
                      suffixIcon: IconButton(
                        tooltip: _obscureConfirmPassword
                            ? 'Show confirmation password'
                            : 'Hide confirmation password',
                        onPressed: isLoading
                            ? null
                            : () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                        icon: Icon(
                          _obscureConfirmPassword
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
