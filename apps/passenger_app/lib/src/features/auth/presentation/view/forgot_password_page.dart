import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:passenger_app/src/features/auth/presentation/validation/auth_form_validator.dart';
import 'package:design_system/design_system.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ForgotPasswordBloc>(
      create: (context) => Modular.get<ForgotPasswordBloc>(),
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

  String? _emailError;
  String? _submissionError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitResetLink(BuildContext context) {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();

    setState(() {
      _submissionError = null;
      _emailError = authFormValidator.email(email);
    });

    if (_emailError != null) {
      return;
    }

    BlocProvider.of<ForgotPasswordBloc>(context)
        .add(ForgotPasswordSubmitted(email: email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasColor,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface.withValues(alpha: 0),
        elevation: 0,
        leading: Center(
          child: IconButton(
            onPressed: () => context.pop(),
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
              setState(() => _submissionError = state.errorMessage);
            }
          },
          builder: (context, state) {
            final isLoading = state is ForgotPasswordLoading;
            final effectiveEmailError = _emailError ?? _submissionError;

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Forgot Password?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "No worries, we'll send you reset instructions. Please enter the email address linked to your account.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: context.colorScheme.onSurfaceVariant,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: context.colorScheme.onSurfaceVariant,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Hero(
                          tag: 'auth_email_field',
                          child: Material(
                            type: MaterialType.transparency,
                            child: TextField(
                              style: TextStyle(
                                color: context.colorScheme.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              keyboardType: TextInputType.emailAddress,
                              controller: _emailController,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submitResetLink(context),
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
                                    color: context.colorScheme.onSurfaceVariant,
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
                                    width: 1.0,
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
                      ],
                    ),
                  ),
                  Hero(
                    tag: 'auth_primary_button',
                    child: Material(
                      type: MaterialType.transparency,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => _submitResetLink(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colorScheme.onSurface,
                          foregroundColor: context.colorScheme.onPrimary,
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
                                'Reset Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
