import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/bloc/reset_password_confirm/reset_password_confirm_bloc.dart';
import 'package:passenger_app/src/features/auth/view/validation/auth_form_validator.dart';
import 'package:shared_ui/shared_ui.dart';

class ResetPasswordConfirmPage extends StatelessWidget {
  final String email;
  final String code;

  const ResetPasswordConfirmPage({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ResetPasswordConfirmBloc>(
      create: (context) => Modular.get<ResetPasswordConfirmBloc>(),
      child: _ResetPasswordConfirmPageContent(email: email, code: code),
    );
  }
}

class _ResetPasswordConfirmPageContent extends StatefulWidget {
  final String email;
  final String code;

  const _ResetPasswordConfirmPageContent({
    required this.email,
    required this.code,
  });

  @override
  State<_ResetPasswordConfirmPageContent> createState() =>
      _ResetPasswordConfirmPageContentState();
}

class _ResetPasswordConfirmPageContentState
    extends State<_ResetPasswordConfirmPageContent> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _newPasswordError;
  String? _confirmPasswordError;
  String? _submissionError;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitNewPassword(BuildContext context) {
    FocusScope.of(context).unfocus();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    setState(() {
      _submissionError = null;
      _newPasswordError = authFormValidator.password(newPassword);
      _confirmPasswordError = authFormValidator.confirmation(
        newPassword,
        confirmPassword,
      );
    });

    if (_newPasswordError != null || _confirmPasswordError != null) {
      return;
    }

    BlocProvider.of<ResetPasswordConfirmBloc>(context).add(
      ResetPasswordConfirmSubmitted(
        email: widget.email,
        code: widget.code,
        newPassword: newPassword,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface.withValues(alpha: 0),
        elevation: 0,
        leading: Center(
          child: IconButton(
            onPressed: () => context.pop(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(shape: const CircleBorder()),
            icon: const Icon(
              LucideIcons.arrow_left,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: BlocConsumer<ResetPasswordConfirmBloc, ResetPasswordConfirmState>(
          listener: (context, state) {
            if (state is ResetPasswordConfirmSuccess) {
              CustomToast.show(context, 'Password updated successfully!');
              context.goNamed(AuthRoutes.signin);
            } else if (state is ResetPasswordConfirmFailure) {
              setState(() => _submissionError = state.errorMessage);
            }
          },
          builder: (context, state) {
            final isLoading = state is ResetPasswordConfirmLoading;

            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
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
                            const SizedBox(height: 20),
                            const Text(
                              'Set New Password',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Your new password must be different from previous passwords.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
                                color: AppTheme.tertiaryColor,
                                height: 1.5,
                              ),
                            ),
                            if (_submissionError != null) ...[
                              const SizedBox(height: 16),
                              Text(
                                _submissionError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppTheme.cancel,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 40),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'New Password',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.tertiaryColor,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _newPasswordController,
                              obscureText: _obscureNewPassword,
                              textInputAction: TextInputAction.next,
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              onChanged: (_) {
                                if (_newPasswordError != null ||
                                    _submissionError != null) {
                                  setState(() {
                                    _newPasswordError = null;
                                    _submissionError = null;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'At least 8 characters',
                                errorText: _newPasswordError,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Icon(
                                    LucideIcons.lock,
                                    size: 20,
                                    color: AppTheme.fieldLabel,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureNewPassword
                                        ? LucideIcons.eye_off
                                        : LucideIcons.eye,
                                    size: 20,
                                    color: AppTheme.tertiaryColor,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureNewPassword =
                                        !_obscureNewPassword,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppTheme.surface,
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
                            const SizedBox(height: 20),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Confirm Password',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.tertiaryColor,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submitNewPassword(context),
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                              onChanged: (_) {
                                if (_confirmPasswordError != null ||
                                    _submissionError != null) {
                                  setState(() {
                                    _confirmPasswordError = null;
                                    _submissionError = null;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                hintText: 'Re-enter your password',
                                errorText: _confirmPasswordError,
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Icon(
                                    LucideIcons.lock,
                                    size: 20,
                                    color: AppTheme.fieldLabel,
                                  ),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? LucideIcons.eye_off
                                        : LucideIcons.eye,
                                    size: 20,
                                    color: AppTheme.tertiaryColor,
                                  ),
                                  onPressed: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword,
                                  ),
                                ),
                                filled: true,
                                fillColor: AppTheme.surface,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () => _submitNewPassword(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: AppTheme.activeControlForeground,
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
                                  color: AppTheme.surface,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save New Password',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
