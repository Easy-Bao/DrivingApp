import 'package:design_system/design_system.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/auth/presentation/view/widgets/driver_auth_layout.dart';
import 'package:driver/src/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key, required this.forgotPasswordBloc});

  final ForgotPasswordBloc forgotPasswordBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForgotPasswordBloc>(
      create: (_) => forgotPasswordBloc,
      child: const _ForgotPasswordPageContent(),
    );
  }
}

class _ForgotPasswordPageContent extends StatefulWidget {
  const _ForgotPasswordPageContent();

  @override
  State<_ForgotPasswordPageContent> createState() =>
      _ForgotPasswordPageContentState();
}

class _ForgotPasswordPageContentState
    extends State<_ForgotPasswordPageContent> {
  final TextEditingController _emailController = TextEditingController();

  final _emailFocus = FocusNode();
  String? _emailError;
  String _submittedEmail = '';

  @override
  void dispose() {
    _emailFocus.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submitResetLink(BuildContext context) {
    if (BlocProvider.of<ForgotPasswordBloc>(context).state
        is ForgotPasswordLoading) {
      return;
    }
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _emailError = 'Enter a valid email address.');
      _emailFocus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    _submittedEmail = email;
    BlocProvider.of<ForgotPasswordBloc>(context)
        .add(ForgotPasswordSubmitted(email: email));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
      listener: (context, state) {
        if (state is ForgotPasswordSuccess) {
          context.pushReplacementNamed(
            AuthRoutes.resetPassword,
            extra: _submittedEmail,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is ForgotPasswordLoading;
        return DriverAuthLayout(
          onBack: () => context.pop(),
          title: 'Forgot password?',
          description: 'We’ll email you a verification code. Enter the email address linked to your account.',
          footer: FilledButton(
            onPressed: isLoading ? null : () => _submitResetLink(context),
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: context.colorScheme.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Send code'),
          ),
          children: [
            if (state is ForgotPasswordFailure) ...[
              AppErrorBanner(
                message: state.errorMessage,
                onRetry: () => _submitResetLink(context),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text('Email address', style: context.textStyles.labelMedium),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              enabled: !isLoading,
              focusNode: _emailFocus,
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              autocorrect: false,
              onChanged: (_) {
                if (_emailError != null) {
                  setState(() => _emailError = null);
                }
              },
              onSubmitted: (_) => _submitResetLink(context),
              decoration: InputDecoration(
                hintText: 'you@example.com',
                errorText: _emailError,
                prefixIcon: const Icon(LucideIcons.mail, size: 18),
              ),
            ),
          ],
        );
      },
    );
  }
}
