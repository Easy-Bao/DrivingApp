import 'package:driver_app/src/features/auth/presentation/bloc/forgot_password/forgot_password_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submitResetLink(BuildContext context) {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      CustomToast.show(context, 'Please enter your email');
      return;
    }

    BlocProvider.of<ForgotPasswordBloc>(
      context,
    ).add(ForgotPasswordSubmitted(email: email));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: context.colorScheme.surface.withValues(alpha: 0),
        elevation: 0,
        leading: IconButton(
          style: IconButton.styleFrom(shape: const CircleBorder()),
          icon: Icon(
            LucideIcons.arrow_left,
            color: context.colorScheme.onSurface,
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
            final errorMessage = state is ForgotPasswordFailure
                ? state.errorMessage
                : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
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
                            Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
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
                            if (errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.error.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  errorMessage,
                                  style: TextStyle(
                                    color: context.colorScheme.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Email Address',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
                                  keyboardType: TextInputType.emailAddress,
                                  controller: _emailController,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) => _submitResetLink(context),
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(left: 10),
                                      child: Icon(LucideIcons.mail, size: 20),
                                    ),
                                    filled: false,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(32),
                                      borderSide: BorderSide(
                                        color: context.colorScheme.onSurface
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(32),
                                      borderSide: BorderSide(
                                        color: context.colorScheme.onSurface,
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
                                  backgroundColor: context.colorScheme.primary,
                                  foregroundColor:
                                      context.colorScheme.onPrimary,
                                  minimumSize: const Size.fromHeight(60),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  elevation: 0,
                                ),
                                child: isLoading
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: context.colorScheme.onPrimary,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Send Reset Link',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => context.pop(),
                            child: Text(
                              'Back to Login',
                              style: TextStyle(
                                color: context.colorScheme.onSurface,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
