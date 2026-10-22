import 'package:design_system/design_system.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/auth/presentation/bloc/reset_password/reset_password_bloc.dart';
import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          constraints: const BoxConstraints(
            minWidth: AppSize.minimumTouchTarget,
            minHeight: AppSize.minimumTouchTarget,
          ),
          style: IconButton.styleFrom(shape: const CircleBorder()),
          icon: Icon(
            LucideIcons.arrow_left,
            color: context.colorScheme.onSurface,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
          listener: (context, state) {
            if (state is ResetPasswordSuccess) {
              context.goNamed(AuthRoutes.signin);
            }
          },
          builder: (context, state) {
            final isLoading = state is ResetPasswordLoading;
            final errorMessage = AppNetworkStatusScope.isUnavailableOf(context)
                ? null
                : state is ResetPasswordFailure
                ? state.errorMessage
                : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Reset Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter the verification code sent to ${widget.email} and choose a new password.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: context.colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (errorMessage != null) ...[
                    AppErrorBanner(
                      message: errorMessage,
                      onRetry: () => _submit(context),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    decoration: const InputDecoration(
                      hintText: 'Verification code',
                      prefixIcon: Icon(LucideIcons.shield_check, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.newPassword],
                    onSubmitted: (_) => _submit(context),
                    decoration: InputDecoration(
                      hintText: 'New password',
                      prefixIcon: const Icon(LucideIcons.lock, size: 20),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        icon: Icon(
                          _obscurePassword
                              ? LucideIcons.eye
                              : LucideIcons.eye_off,
                          size: 20,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: isLoading ? null : () => _submit(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
