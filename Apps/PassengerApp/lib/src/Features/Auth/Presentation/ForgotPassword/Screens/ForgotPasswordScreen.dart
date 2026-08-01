import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/Features/Auth/Presentation/ForgotPassword/Bloc/ForgotPasswordBloc.dart';
import 'package:shared_ui/SharedUi.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForgotPasswordBloc>(
      create: (context) => Modular.get<ForgotPasswordBloc>(),
      child: const _ForgotPasswordScreenContent(),
    );
  }
}

class _ForgotPasswordScreenContent extends StatefulWidget {
  const _ForgotPasswordScreenContent();

  @override
  State<_ForgotPasswordScreenContent> createState() =>
      _ForgotPasswordScreenContentState();
}

class _ForgotPasswordScreenContentState
    extends State<_ForgotPasswordScreenContent> {
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  final TextEditingController _emailController = TextEditingController();

  String? _emailError;
  bool _isServerErrorCleared = false;
  Timer? _validationErrorTimer;

  @override
  void dispose() {
    _validationErrorTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startErrorAutoDismissTimer() {
    _validationErrorTimer?.cancel();
    _validationErrorTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _emailError = null;
          _isServerErrorCleared = true;
        });
      }
    });
  }

  void _submitResetLink(BuildContext context) {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();

    setState(() {
      _isServerErrorCleared = false;
      if (email.isEmpty) {
        _emailError = 'Please enter your email';
      } else if (!_emailRegex.hasMatch(email)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }
    });

    if (_emailError != null) {
      _startErrorAutoDismissTimer();
      return;
    }

    BlocProvider.of<ForgotPasswordBloc>(context).add(
      ForgotPasswordSubmitted(email: email),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<ForgotPasswordBloc, ForgotPasswordState>(
          listener: (context, state) {
            if (state is ForgotPasswordSuccess) {
              CustomToast.show(
                context,
                'Reset link sent to ${_emailController.text.trim()}',
              );
              context.pop();
            } else if (state is ForgotPasswordFailure) {
              CustomToast.show(context, state.errorMessage);
            }
          },
          builder: (context, state) {
            final isLoading = state is ForgotPasswordLoading;
            final serverErrorMessage =
                state is ForgotPasswordFailure && !_isServerErrorCleared ? state.errorMessage : null;

            final effectiveEmailError = _emailError ?? serverErrorMessage;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "No worries, we'll send you reset instructions. Please enter the email address linked to your account.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.tertiaryColor,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 40),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'EMAIL ADDRESS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.tertiaryColor,
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
                                  style: const TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  controller: _emailController,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submitResetLink(context),
                                  onChanged: (_) {
                                    if (_emailError != null ||
                                        _isServerErrorCleared == false) {
                                      setState(() {
                                        _emailError = null;
                                        _isServerErrorCleared = true;
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    errorText: effectiveEmailError,
                                    errorStyle: const TextStyle(
                                      color: AppTheme.cancel,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Icon(
                                        LucideIcons.mail,
                                        size: 20,
                                        color: Color(0xFF495057),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: const BorderSide(
                                        color: AppTheme.borderSide,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: const BorderSide(
                                        color: AppTheme.primaryColor,
                                        width: 1.5,
                                      ),
                                    ),
                                    errorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: const BorderSide(
                                        color: AppTheme.cancel,
                                        width: 1.0,
                                      ),
                                    ),
                                    focusedErrorBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: const BorderSide(
                                        color: AppTheme.cancel,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Column(
                        children: [
                          Hero(
                            tag: 'auth_primary_button',
                            child: Material(
                              type: MaterialType.transparency,
                              child: ElevatedButton(
                                onPressed: isLoading
                                    ? null
                                    : () => _submitResetLink(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(56),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(36),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Reset Password',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton.icon(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              LucideIcons.arrow_left,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                            label: const Text(
                              'Back to Sign In',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
