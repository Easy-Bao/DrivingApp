import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/bloc/session/session_bloc.dart';
import 'package:passenger_app/src/features/auth/bloc/sign_in/sign_in_bloc.dart';
import 'package:passenger_app/src/features/auth/view/validation/auth_form_validator.dart';
import 'package:passenger_app/src/features/auth/view/widgets/social_login_widget.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class SigninPage extends StatelessWidget {
  const SigninPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignInBloc>(
      create: (context) => Modular.get<SignInBloc>(),
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool isChecked = false;

  String? _emailError;
  String? _passwordError;
  String? _submissionError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface.withValues(alpha: 0),
        elevation: 0,
        leading: Center(
          child: IconButton(
            onPressed: () => context.goNamed(HomeRoutes.home),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(shape: const CircleBorder()),
            icon: Icon(
              LucideIcons.arrow_left,
              color: context.colorScheme.onSurface,
              size: 20,
            ),
          ),
        ),
        centerTitle: true,
        title: Image.asset(
          'assets/logo/applogo.png',
          package: 'shared_ui',
          height: 150,
          fit: BoxFit.cover,
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<SignInBloc, SignInState>(
          listener: (context, state) {
            if (state is SignInSuccess) {
              BlocProvider.of<SessionBloc>(context).add(
                SessionAuthenticatedRequested(
                  passengerId: state.credentials.passengerId,
                  passengerName: state.credentials.passengerName,
                ),
              );
              context.goNamed(HomeRoutes.home);
            } else if (state is SignInNeedsVerification) {
              unawaited(
                context.pushNamed(
                  AuthRoutes.verifyOtp,
                  extra: {'email': state.email},
                ),
              );
            } else if (state is SignInFailure) {
              setState(() => _submissionError = state.errorMessage);
            }
          },
          builder: (context, state) {
            final isLoading = state is SignInLoading;
            final effectiveEmailError = _emailError ?? _submissionError;
            final effectivePasswordError = _passwordError;

            return LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 20),
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  'Sign in to EasyRide',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Enter your credentials to continue',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Email Address',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: context.colorScheme.onSurfaceVariant,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Hero(
                            tag: 'auth_email_field',
                            child: Material(
                              type: MaterialType.transparency,
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: TextStyle(
                                  color: context.colorScheme.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                onChanged: (_) {
                                  if (_emailError != null ||
                                      _submissionError != null) {
                                    setState(() {
                                      _emailError = null;
                                      _submissionError = null;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Email',
                                  errorText: effectiveEmailError,
                                  errorStyle: TextStyle(
                                    color: context.colorScheme.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Icon(
                                      LucideIcons.mail,
                                      size: 20,
                                      color:
                                          context.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: context.colorScheme.surface,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(36),
                                    borderSide: BorderSide(
                                      color: context.colorScheme.outlineVariant,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(36),
                                    borderSide: BorderSide(
                                      color: context.colorScheme.onSurface,
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(36),
                                    borderSide: BorderSide(
                                      color: context.colorScheme.error,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(36),
                                    borderSide: BorderSide(
                                      color: context.colorScheme.error,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Password',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: context.colorScheme.onSurfaceVariant,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Hero(
                            tag: 'auth_password_field',
                            child: Material(
                              type: MaterialType.transparency,
                              child: TextField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) => _submitSignIn(context),
                                style: TextStyle(
                                  color: context.colorScheme.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                onChanged: (_) {
                                  if (_passwordError != null ||
                                      _submissionError != null) {
                                    setState(() {
                                      _passwordError = null;
                                      _submissionError = null;
                                    });
                                  }
                                },
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  errorText: effectivePasswordError,
                                  errorStyle: TextStyle(
                                    color: context.colorScheme.error,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: Icon(
                                      LucideIcons.lock,
                                      size: 20,
                                      color:
                                          context.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? LucideIcons.eye
                                          : LucideIcons.eye_off,
                                      size: 20,
                                      color:
                                          context.colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () => setState(
                                      () => _isPasswordVisible =
                                          !_isPasswordVisible,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: context.colorScheme.surface,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(36),
                                    borderSide: BorderSide(
                                      color: context.colorScheme.outlineVariant,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(36),
                                    borderSide: BorderSide(
                                      color: context.colorScheme.onSurface,
                                      width: 1.5,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(36),
                                    borderSide: BorderSide(
                                      color: context.colorScheme.error,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(36),
                                    borderSide: BorderSide(
                                      color: context.colorScheme.error,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: isChecked,
                                    activeColor: context.colorScheme.onSurface,
                                    onChanged: (bool? val) {
                                      setState(() {
                                        isChecked = val ?? false;
                                      });
                                    },
                                  ),
                                  Text(
                                    'Remember me',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color:
                                          context.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  unawaited(
                                    context.pushNamed(
                                      AuthRoutes.forgotPassword,
                                    ),
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Hero(
                            tag: 'auth_primary_button',
                            child: Material(
                              type: MaterialType.transparency,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => _submitSignIn(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      context.colorScheme.onSurface,
                                  foregroundColor:
                                      context.colorScheme.onPrimary,
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(36),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: context.colorScheme.surface,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SocialLoginWidget(
                            onGoogleTap: () {
                              CustomToast.show(
                                context,
                                'Google Sign-In coming soon',
                              );
                            },
                          ),
                          const Spacer(),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account?",
                                  style: TextStyle(
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    unawaited(
                                      context.pushNamed(AuthRoutes.signup),
                                    );
                                  },
                                  child: Text(
                                    'Sign up',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitSignIn(BuildContext context) {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _submissionError = null;
      _emailError = authFormValidator.email(email);
      _passwordError = authFormValidator.password(password, minimumLength: 1);
    });

    if (_emailError != null || _passwordError != null) {
      return;
    }

    BlocProvider.of<SignInBloc>(
      context,
    ).add(SignInSubmitted(email: email, password: password));
  }
}
