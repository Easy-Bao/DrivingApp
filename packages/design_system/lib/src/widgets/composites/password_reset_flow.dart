import 'dart:async';

import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:design_system/src/widgets/inputs/verification_code_field.dart';
import 'package:design_system/src/widgets/layout/auth_layout.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class AppPasswordResetFlow extends StatefulWidget {
  const AppPasswordResetFlow({
    super.key,
    required this.email,
    required this.minimumPasswordLength,
    required this.onBack,
    required this.onSubmit,
    required this.onResend,
    this.onVerifyCode,
    this.onCodeChanged,
    this.onPasswordChanged,
    this.onStepBack,
    this.initialCode = '',
    this.isVerifyingCode = false,
    this.isCodeVerified = false,
    this.isSubmitting = false,
    this.isResending = false,
    this.errorMessage,
  });

  final String email;
  final int minimumPasswordLength;
  final VoidCallback onBack;
  final void Function(String code, String password) onSubmit;
  final VoidCallback onResend;
  final ValueChanged<String>? onVerifyCode;
  final VoidCallback? onCodeChanged;
  final VoidCallback? onPasswordChanged;
  final VoidCallback? onStepBack;
  final String initialCode;
  final bool isVerifyingCode;
  final bool isCodeVerified;
  final bool isSubmitting;
  final bool isResending;
  final String? errorMessage;

  @override
  State<AppPasswordResetFlow> createState() => _AppPasswordResetFlowState();
}

class _AppPasswordResetFlowState extends State<AppPasswordResetFlow> {
  late final TextEditingController _code;
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  final _codeFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmationFocus = FocusNode();
  late bool _passwordStep;
  bool _showPassword = false;
  bool _showConfirmation = false;
  bool _dismissedError = false;
  bool _suppressingCodeListener = false;
  String? _codeError;
  String? _passwordError;
  String? _confirmationError;
  Timer? _resendTimer;
  final ValueNotifier<int> _secondsRemaining = ValueNotifier<int>(60);

  bool get _busy =>
      widget.isSubmitting || widget.isVerifyingCode || widget.isResending;
  bool get _completeCode => RegExp(r'^\d{6}$').hasMatch(_code.text);
  bool get _longEnough => _password.text.length >= widget.minimumPasswordLength;
  bool get _passwordsMatch =>
      _confirmation.text.isNotEmpty && _password.text == _confirmation.text;
  String? get _activeErrorMessage =>
      _dismissedError ? null : widget.errorMessage;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initialCode);
    _passwordStep = widget.onVerifyCode == null
        ? _completeCode
        : widget.isCodeVerified && _completeCode;
    _code.addListener(_handleCodeChanged);
    _password.addListener(_refresh);
    _confirmation.addListener(_refresh);
    _startResendTimer();
  }

  @override
  void didUpdateWidget(covariant AppPasswordResetFlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorMessage != oldWidget.errorMessage ||
        (oldWidget.isVerifyingCode && !widget.isVerifyingCode) ||
        (oldWidget.isSubmitting && !widget.isSubmitting)) {
      _dismissedError = false;
    }
    if (!oldWidget.isCodeVerified &&
        widget.isCodeVerified &&
        !oldWidget.isResending &&
        widget.errorMessage == null &&
        !_passwordStep &&
        _completeCode) {
      FocusScope.of(context).unfocus();
      _passwordStep = true;
      _codeError = null;
      _dismissedError = true;
    }
    if (oldWidget.isResending &&
        !widget.isResending &&
        widget.errorMessage == null) {
      _suppressingCodeListener = true;
      try {
        _code.clear();
      } finally {
        _suppressingCodeListener = false;
      }
      _passwordStep = false;
      _codeError = null;
      _startResendTimer();
    }
  }

  void _handleCodeChanged() {
    if (_suppressingCodeListener) return;
    final hadInlineError = _codeError != null || !_dismissedError;
    _codeError = null;
    _dismissedError = true;
    if (hadInlineError) {
      widget.onCodeChanged?.call();
    }
    setState(() {});
  }

  void _refresh() => setState(() {});

  void _startResendTimer() {
    _resendTimer?.cancel();
    _secondsRemaining.value = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final next = _secondsRemaining.value - 1;
      if (next <= 0) {
        _secondsRemaining.value = 0;
        timer.cancel();
      } else {
        _secondsRemaining.value = next;
      }
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _secondsRemaining.dispose();
    _code.removeListener(_handleCodeChanged);
    _password.removeListener(_refresh);
    _confirmation.removeListener(_refresh);
    _code.dispose();
    _password.dispose();
    _confirmation.dispose();
    _codeFocus.dispose();
    _passwordFocus.dispose();
    _confirmationFocus.dispose();
    super.dispose();
  }

  void _continue() {
    if (_busy) return;
    if (!_completeCode) {
      setState(() => _codeError = 'Enter the 6-digit verification code.');
      _codeFocus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _codeError = null;
      _dismissedError = false;
    });
    final verifyCode = widget.onVerifyCode;
    if (verifyCode != null) {
      if (widget.isCodeVerified) {
        setState(() => _passwordStep = true);
      } else {
        verifyCode(_code.text);
      }
      return;
    }
    setState(() => _passwordStep = true);
  }

  void _back() {
    if (_busy) return;
    if (_passwordStep) {
      FocusScope.of(context).unfocus();
      setState(() {
        _passwordStep = false;
        _dismissedError = true;
      });
      widget.onStepBack?.call();
    } else {
      widget.onBack();
    }
  }

  void _submit() {
    if (_busy) return;
    setState(() {
      _dismissedError = false;
      _passwordError = _longEnough
          ? null
          : 'Use at least ${widget.minimumPasswordLength} characters.';
      _confirmationError = _passwordsMatch ? null : 'Passwords do not match.';
    });
    if (_passwordError != null || _confirmationError != null) {
      (_passwordError != null ? _passwordFocus : _confirmationFocus)
          .requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    widget.onSubmit(_code.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final codeError = _codeError ?? _activeErrorMessage;
    final submitError = _activeErrorMessage;
    final showButtonSpinner = _passwordStep
        ? widget.isSubmitting
        : widget.isVerifyingCode;

    return PopScope(
      canPop: !_passwordStep && !_busy,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AppAuthLayout(
        onBack: _back,
        title: _passwordStep ? 'Create new password' : 'Check your email',
        description: _passwordStep
            ? 'Choose a strong password for your account.'
            : 'We sent a 6-digit verification code to ${widget.email.trim()}.',
        descriptionHighlight: _passwordStep ? null : widget.email.trim(),
        footer: FilledButton(
          onPressed: _busy || (!_passwordStep && !_completeCode)
              ? null
              : _passwordStep
              ? _submit
              : _continue,
          child: showButtonSpinner
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: context.colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : Text(_passwordStep ? 'Reset password' : 'Continue'),
        ),
        children: [
          if (!_passwordStep) ...[
            Semantics(
              liveRegion: codeError != null,
              child: AppVerificationCodeField(
                controller: _code,
                focusNode: _codeFocus,
                enabled: !_busy,
                errorText: codeError,
                onSubmitted: (_) => _continue(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Didn’t get a code?',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                ValueListenableBuilder<int>(
                  valueListenable: _secondsRemaining,
                  builder: (context, secondsRemaining, _) => TextButton(
                    onPressed: secondsRemaining == 0 && !_busy
                        ? widget.onResend
                        : null,
                    child: Text(
                      widget.isResending
                          ? 'Sending…'
                          : secondsRemaining == 0
                          ? 'Resend code'
                          : 'Resend in ${secondsRemaining ~/ 60}:${(secondsRemaining % 60).toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _passwordField(
                    label: 'New password',
                    controller: _password,
                    focus: _passwordFocus,
                    visible: _showPassword,
                    onToggle: () =>
                        setState(() => _showPassword = !_showPassword),
                    error: _passwordError,
                    confirmation: false,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _passwordField(
                    label: 'Confirm password',
                    controller: _confirmation,
                    focus: _confirmationFocus,
                    visible: _showConfirmation,
                    onToggle: () =>
                        setState(() => _showConfirmation = !_showConfirmation),
                    error: _confirmationError,
                    confirmation: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _requirement(
              'At least ${widget.minimumPasswordLength} characters',
              _longEnough,
            ),
            const SizedBox(height: AppSpacing.sm),
            _requirement('Passwords match', _passwordsMatch),
            if (submitError != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                liveRegion: true,
                child: Text(
                  submitError,
                  key: const ValueKey('password-reset-bottom-error'),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colorScheme.error,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required FocusNode focus,
    required bool visible,
    required VoidCallback onToggle,
    required bool confirmation,
    String? error,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: context.textStyles.labelMedium),
      const SizedBox(height: AppSpacing.sm),
      TextField(
        controller: controller,
        focusNode: focus,
        enabled: !_busy,
        obscureText: !visible,
        autofillHints: const [AutofillHints.newPassword],
        autocorrect: false,
        enableSuggestions: false,
        textInputAction: confirmation
            ? TextInputAction.done
            : TextInputAction.next,
        onSubmitted: confirmation ? (_) => _submit() : null,
        onChanged: (_) {
          setState(() {
            _dismissedError = true;
            if (confirmation) {
              _confirmationError = null;
            } else {
              _passwordError = null;
            }
          });
          widget.onPasswordChanged?.call();
        },
        decoration: InputDecoration(
          hintText: confirmation
              ? 'Re-enter your password'
              : 'Enter a new password',
          errorText: error,
          prefixIcon: const Icon(LucideIcons.lock, size: 18),
          suffixIcon: IconButton(
            tooltip: confirmation
                ? visible
                      ? 'Hide confirmation password'
                      : 'Show confirmation password'
                : visible
                ? 'Hide password'
                : 'Show password',
            onPressed: _busy ? null : onToggle,
            icon: Icon(
              visible ? LucideIcons.eye : LucideIcons.eye_off,
              size: 18,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _requirement(String label, bool met) => Semantics(
    label: '$label, ${met ? 'met' : 'not met'}',
    child: ExcludeSemantics(
      child: Row(
        children: [
          Icon(
            met
                ? Icons.check_circle_outline_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: met
                ? context.semanticColors.success
                : context.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: context.textStyles.bodySmall?.copyWith(
                color: met
                    ? context.semanticColors.success
                    : context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
