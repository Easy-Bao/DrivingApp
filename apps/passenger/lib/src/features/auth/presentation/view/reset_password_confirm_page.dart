import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
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
}) extends StatelessWidget {
  final String email;
  final String code;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ResetPasswordConfirmBloc>(
      create: (context) => Modular.get<ResetPasswordConfirmBloc>(),
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
        child:
            BlocConsumer<ResetPasswordConfirmBloc, ResetPasswordConfirmState>(
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
                                Text(
                                  'Set New Password',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: context.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Your new password must be different from previous passwords.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: context.colorScheme.onSurfaceVariant,
                                    height: 1.5,
                                  ),
                                ),
                                if (_submissionError != null) ...[
                                  const SizedBox(height: 16),
                                  Text(
                                    _submissionError!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.colorScheme.error,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 40),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'New Password',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          context.colorScheme.onSurfaceVariant,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _newPasswordController,
                                  obscureText: _obscureNewPassword,
                                  textInputAction: TextInputAction.next,
                                  style: TextStyle(
                                    color: context.colorScheme.onSurface,
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
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Icon(
                                        LucideIcons.lock,
                                        size: 20,
                                        color: context
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNewPassword
                                            ? LucideIcons.eye_off
                                            : LucideIcons.eye,
                                        size: 20,
                                        color: context
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureNewPassword =
                                            !_obscureNewPassword,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: context.colorScheme.surface,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: BorderSide(
                                        color:
                                            context.colorScheme.outlineVariant,
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
                                const SizedBox(height: 20),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Confirm Password',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color:
                                          context.colorScheme.onSurfaceVariant,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  textInputAction: TextInputAction.done,
                                  onSubmitted: (_) =>
                                      _submitNewPassword(context),
                                  style: TextStyle(
                                    color: context.colorScheme.onSurface,
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
                                    prefixIcon: Padding(
                                      padding: const EdgeInsets.only(left: 10),
                                      child: Icon(
                                        LucideIcons.lock,
                                        size: 20,
                                        color: context
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? LucideIcons.eye_off
                                            : LucideIcons.eye,
                                        size: 20,
                                        color: context
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureConfirmPassword =
                                            !_obscureConfirmPassword,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: context.colorScheme.surface,
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(36),
                                      borderSide: BorderSide(
                                        color:
                                            context.colorScheme.outlineVariant,
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
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () => _submitNewPassword(context),
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
