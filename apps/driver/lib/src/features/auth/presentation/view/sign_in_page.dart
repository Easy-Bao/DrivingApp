import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/auth/auth_routes.dart';
import 'package:driver/src/features/auth/presentation/view/widgets/driver_auth_layout.dart';
import 'package:driver/src/features/settings/settings_routes.dart';
import 'package:driver/src/features/auth/presentation/bloc/sign_in/sign_in_bloc.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class SigninPage extends StatelessWidget {
  const SigninPage({super.key, required this.signInBloc});

  final SignInBloc signInBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInBloc>(
      create: (_) => signInBloc,
      child: const _SigninPageContent(),
    );
  }
}

class _SigninPageContent extends StatefulWidget {
  const _SigninPageContent();

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
  String? _emailError;
  String? _passwordError;

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
        return DriverAuthLayout(
          title: 'Driver Portal',
          description: 'Sign in to manage your rides and earnings.',
          footer: TextButton(
            onPressed: () => context.pushNamed(SettingsRoutes.terms),
            child: Text.rich(
              const TextSpan(
                text: 'By signing in, you agree to the EasyRide ',
                children: [
                  TextSpan(
                    text: 'Terms of Service.',
                    style: TextStyle(decoration: TextDecoration.underline),
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
