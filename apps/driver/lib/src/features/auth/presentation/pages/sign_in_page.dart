import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:driver/src/features/settings/settings_routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({
    super.key,
    required this.signInBloc,
    this.sessionExpired = false,
  });

  final SignInBloc signInBloc;
  final bool sessionExpired;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInBloc>(
      create: (_) => signInBloc,
      child: _SigninPageContent(sessionExpired: sessionExpired),
    );
  }
}

class _SigninPageContent extends StatefulWidget {
  const _SigninPageContent({this.sessionExpired = false});

  final bool sessionExpired;

  @override
  State<_SigninPageContent> createState() => _SigninPageContentState();
}

class _SigninPageContentState extends State<_SigninPageContent> {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isPasswordVisible = false;
  late bool _showSessionExpiredNotice = widget.sessionExpired;
  String? _emailError;
  String? _passwordError;

  @override
  void didUpdateWidget(covariant _SigninPageContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessionExpired && !oldWidget.sessionExpired) {
      _showSessionExpiredNotice = true;
    }
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitSignIn(BuildContext context) {
    if (BlocProvider.of<SignInBloc>(context).state is SignInLoading) return;
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      if (email.isEmpty) {
        _emailError = 'Enter your email address.';
      } else if (!_emailRegex.hasMatch(email)) {
        _emailError = 'Enter a valid email address.';
      } else {
        _emailError = null;
      }
      _passwordError = password.isEmpty ? 'Enter your password.' : null;
    });

    if (_emailError != null || _passwordError != null) {
      (_emailError != null ? _emailFocus : _passwordFocus).requestFocus();
      return;
    }

    if (_showSessionExpiredNotice) {
      setState(() => _showSessionExpiredNotice = false);
    }

    BlocProvider.of<SignInBloc>(context)
        .add(SignInSubmitted(email: email, password: password));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SignInBloc, SignInState>(
      listener: (context, state) {
        if (state is SignInSuccess) {
          TextInput.finishAutofillContext();
          context.goNamed(DashboardRoutes.dashboard);
        }
      },
      builder: (context, state) {
        final isLoading = state is SignInLoading;
        return AppAuthLayout(
          title: 'Driver Portal',
          description: 'Sign in to manage your rides and earnings.',
          footer: TextButton(
            onPressed: () => context.pushNamed(SettingsRoutes.terms),
            child: Text.rich(
              TextSpan(
                text: 'By signing in, you agree to the EasyRide ',
                children: [
                  TextSpan(
                    text: 'Terms of Service.',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          children: [
            if (_showSessionExpiredNotice && state is! SignInFailure) ...[
              Semantics(
                liveRegion: true,
                child: Container(
                  key: const ValueKey<String>('driver-session-expired-notice'),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.semanticColors.warningContainer,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Icon(
                          LucideIcons.triangle_alert,
                          size: 16,
                          color: context.semanticColors.onWarningContainer,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Your session expired. Sign in again to continue.',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.semanticColors.onWarningContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (state is SignInFailure) ...[
              AppErrorBanner(
                message: state.errorMessage,
                onRetry: () => _submitSignIn(context),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Email', style: context.textStyles.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    enabled: !isLoading,
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    onChanged: (_) {
                      if (_emailError != null) {
                        setState(() => _emailError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'you@example.com',
                      errorText: _emailError,
                      prefixIcon: const Icon(LucideIcons.mail, size: 18),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Password', style: context.textStyles.labelMedium),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    enabled: !isLoading,
                    obscureText: !_isPasswordVisible,
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => _submitSignIn(context),
                    onChanged: (_) {
                      if (_passwordError != null) {
                        setState(() => _passwordError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      errorText: _passwordError,
                      prefixIcon: const Icon(LucideIcons.lock, size: 18),
                      suffixIcon: IconButton(
                        tooltip: _isPasswordVisible
                            ? 'Hide password'
                            : 'Show password',
                        onPressed: isLoading
                            ? null
                            : () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible,
                              ),
                        icon: Icon(
                          _isPasswordVisible
                              ? LucideIcons.eye
                              : LucideIcons.eye_off,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLoading
                    ? null
                    : () => unawaited(
                        context.pushNamed(AuthRoutes.forgotPassword),
                      ),
                child: const Text('Forgot password?'),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: isLoading ? null : () => _submitSignIn(context),
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: context.colorScheme.onPrimary,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Sign in'),
            ),
          ],
        );
      },
    );
  }
}
