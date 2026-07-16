import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/di/service_locator.dart';
import 'package:passenger_app/src/core/services/passenger_api_service.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/core/themes/app_themes.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/trip_booking/trip_routes.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _onboardingPageController = PageController();

  int _currentStepIndex = 0;

  final TextEditingController _passengerEmailController = TextEditingController();
  final TextEditingController _passengerPasswordController = TextEditingController();
  final TextEditingController _passengerOtpController = TextEditingController();
  final TextEditingController _passengerNameController = TextEditingController();
  final TextEditingController _passengerPhoneController = TextEditingController();
  final FocusNode _passengerOtpFocusNode = FocusNode();

  bool _isPasswordInputVisible = false;
  bool _isProcessingRequest = false;
  String? _onboardingErrorMessage;

  String _registeredPassengerEmail = '';
  String _sessionJsonWebToken = '';
  String _registeredPassengerId = '';

  Timer? _otpCountdownTimer;
  int _secondsRemainingBeforeOtpResend = 60;

  @override
  void initState() {
    super.initState();
    _passengerOtpController.addListener(_onOtpDigitChange);
  }

  @override
  void dispose() {
    _onboardingPageController.dispose();
    _passengerEmailController.dispose();
    _passengerPasswordController.dispose();
    _passengerOtpController.dispose();
    _passengerNameController.dispose();
    _passengerPhoneController.dispose();
    _passengerOtpFocusNode.dispose();
    _otpCountdownTimer?.cancel();
    super.dispose();
  }

  void _advanceToNextOnboardingPage() {
    unawaited(_onboardingPageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    ));
    setState(() {
      _currentStepIndex++;
      _onboardingErrorMessage = null;
    });
  }

  void _retreatToPreviousOnboardingPage() {
    if (_currentStepIndex == 0) {
      context.pop();
      return;
    }
    unawaited(_onboardingPageController.previousPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    ));
    setState(() {
      _currentStepIndex--;
      _onboardingErrorMessage = null;
    });
  }

  void _startOtpResendCountdownTimer() {
    _otpCountdownTimer?.cancel();
    setState(() => _secondsRemainingBeforeOtpResend = 60);
    _otpCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _secondsRemainingBeforeOtpResend--;
        if (_secondsRemainingBeforeOtpResend <= 0) {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _submitPassengerEmailAndPassword() async {
    final emailAddress = _passengerEmailController.text.trim();
    final passengerPassword = _passengerPasswordController.text;

    final isEmailFormatValid = RegExp(r'^[\w\-.]+@[\w\-]+\.\w{2,}$').hasMatch(emailAddress);
    if (!isEmailFormatValid) {
      setState(() => _onboardingErrorMessage = 'Please enter a valid email address.');
      return;
    }
    if (passengerPassword.length < 8) {
      setState(() => _onboardingErrorMessage = 'Password must be at least 8 characters.');
      return;
    }

    setState(() {
      _isProcessingRequest = true;
      _onboardingErrorMessage = null;
    });

    try {
      final networkResponse = await getIt<PassengerApiService>().registerPassenger(
        name: 'Pending',
        email: emailAddress,
        phone: 'Pending',
        password: passengerPassword,
      );

      if (!mounted) return;

      if (networkResponse != null && networkResponse['needs_verification'] == true) {
        _registeredPassengerEmail = emailAddress;
        _passengerOtpController.clear();
        _startOtpResendCountdownTimer();
        _advanceToNextOnboardingPage();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _passengerOtpFocusNode.requestFocus();
        });
      } else {
        setState(() => _onboardingErrorMessage = 'Unexpected response. Please try again.');
      }
    } catch (apiError) {
      if (!mounted) return;
      final apiErrorMessage = apiError.toString().contains('already exists')
          ? 'This email is already registered. Try signing in instead.'
          : 'Something went wrong. Please try again.';
      setState(() => _onboardingErrorMessage = apiErrorMessage);
    } finally {
      if (mounted) {
        setState(() => _isProcessingRequest = false);
      }
    }
  }

  void _onOtpDigitChange() {
    if (_passengerOtpController.text.length == 6 && !_isProcessingRequest) {
      unawaited(_submitOtpVerificationCode(_passengerOtpController.text));
    }
  }

  Future<void> _submitOtpVerificationCode(String otpCode) async {
    setState(() {
      _isProcessingRequest = true;
      _onboardingErrorMessage = null;
    });

    try {
      final verificationSuccess = await getIt<PassengerApiService>().verifyOtp(
        email: _registeredPassengerEmail,
        code: otpCode,
      );

      if (!mounted) return;

      if (verificationSuccess) {
        final loginResult = await getIt<PassengerApiService>().loginPassenger(
          email: _registeredPassengerEmail,
          password: _passengerPasswordController.text,
        );

        if (!mounted) return;

        if (loginResult != null && loginResult['token'] != null) {
          _sessionJsonWebToken = loginResult['token'] as String;
          _registeredPassengerId =
              (loginResult['passenger'] as Map<String, dynamic>?)?['id'] as String? ??
                  '';
          final secureSession = getIt<SecureSessionService>();
          await secureSession.writeAuthToken(_sessionJsonWebToken);
          if (_registeredPassengerId.isNotEmpty) {
            await secureSession.writePassengerId(_registeredPassengerId);
          }
          _advanceToNextOnboardingPage();
        } else {
          _passengerOtpController.clear();
          setState(() => _onboardingErrorMessage = 'Login failed after verification. Try again.');
        }
      } else {
        _passengerOtpController.clear();
        setState(() => _onboardingErrorMessage = 'Invalid or expired code. Try again.');
      }
    } catch (verificationError) {
      if (!mounted) return;
      _passengerOtpController.clear();
      setState(() => _onboardingErrorMessage = 'Verification failed. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isProcessingRequest = false);
      }
    }
  }

  Future<void> _resendOtpVerificationCode() async {
    if (_secondsRemainingBeforeOtpResend > 0) return;
    setState(() {
      _isProcessingRequest = true;
      _onboardingErrorMessage = null;
    });
    try {
      await getIt<PassengerApiService>().registerPassenger(
        name: 'Pending',
        email: _registeredPassengerEmail,
        phone: 'Pending',
        password: _passengerPasswordController.text,
      );
      if (!mounted) return;
      _startOtpResendCountdownTimer();
      _passengerOtpController.clear();
    } finally {
      if (mounted) {
        setState(() => _isProcessingRequest = false);
      }
    }
  }

  Future<void> _submitPassengerProfileDetails() async {
    final fullName = _passengerNameController.text.trim();
    final phoneNumber = _passengerPhoneController.text.trim();

    if (fullName.isEmpty) {
      setState(() => _onboardingErrorMessage = 'Please enter your name.');
      return;
    }
    if (phoneNumber.isEmpty) {
      setState(() => _onboardingErrorMessage = 'Please enter your phone number.');
      return;
    }

    setState(() {
      _isProcessingRequest = true;
      _onboardingErrorMessage = null;
    });

    try {
      final completionResult = await getIt<PassengerApiService>().updateProfile(
        id: _registeredPassengerId,
        name: fullName,
        phone: phoneNumber,
        email: _registeredPassengerEmail,
      );

      if (!mounted) return;

      if (completionResult != null) {
        context.goNamed(TripRoutes.passengerHome);
      } else {
        setState(() => _onboardingErrorMessage = 'Could not save profile. Please try again.');
      }
    } catch (completionError) {
      if (!mounted) return;
      setState(() => _onboardingErrorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isProcessingRequest = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              _buildOnboardingTopNavigationHeader(),
              Expanded(
                child: PageView(
                  controller: _onboardingPageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildOnboardingEmailAndPasswordStepView(),
                    _buildOnboardingOtpVerificationStepView(),
                    _buildOnboardingProfileCompletionStepView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingTopNavigationHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _retreatToPreviousOnboardingPage,
            icon: const Icon(
              LucideIcons.chevron_left,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            label: const Text(
              'Back',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingEmailAndPasswordStepView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Create your\naccount',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Start with your email. We'll send a verification code to confirm it's you.",
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.primaryColor.withValues(alpha: 0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _buildOnboardingFieldLabel('Email address'),
          const SizedBox(height: 8),
          _buildOnboardingTextField(
            textController: _passengerEmailController,
            placeholderHintText: 'you@example.com',
            inputType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _buildOnboardingFieldLabel('Password'),
          const SizedBox(height: 8),
          _buildOnboardingTextField(
            textController: _passengerPasswordController,
            placeholderHintText: 'At least 8 characters',
            isObscured: !_isPasswordInputVisible,
            suffixButton: IconButton(
              icon: Icon(
                _isPasswordInputVisible ? LucideIcons.eye_off : LucideIcons.eye,
                size: 18,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
              onPressed: () => setState(() => _isPasswordInputVisible = !_isPasswordInputVisible),
            ),
          ),
          if (_onboardingErrorMessage != null) ...[
            const SizedBox(height: 16),
            _buildOnboardingErrorDisplayPanel(_onboardingErrorMessage!),
          ],
          const SizedBox(height: 36),
          _buildOnboardingActionSubmitButton(
            buttonLabelText: 'Continue',
            onActionPressed: _isProcessingRequest ? null : _submitPassengerEmailAndPassword,
            isRequestExecuting: _isProcessingRequest,
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => context.goNamed(AuthRoutes.signin),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14, color: AppTheme.primaryColor),
                  children: [
                    TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                    const TextSpan(
                      text: 'Sign in',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingOtpVerificationStepView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.mail,
              color: AppTheme.primaryColor,
              size: 30,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Check your email',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'We sent a 6-digit code to\n$_registeredPassengerEmail',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.primaryColor.withValues(alpha: 0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => _passengerOtpFocusNode.requestFocus(),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _passengerOtpController,
              builder: (context, value, _) {
                final inputCodeString = value.text;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (digitItemIndex) {
                    final hasEnteredDigit = inputCodeString.length > digitItemIndex;
                    final isFieldCellFocused =
                        inputCodeString.length == digitItemIndex && _passengerOtpFocusNode.hasFocus;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 46,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: hasEnteredDigit
                            ? AppTheme.primaryColor.withValues(alpha: 0.06)
                            : Colors.transparent,
                        border: Border.all(
                          color: _onboardingErrorMessage != null
                              ? AppTheme.cancel
                              : isFieldCellFocused
                                  ? AppTheme.primaryColor
                                  : AppTheme.primaryColor.withValues(alpha: 0.16),
                          width: isFieldCellFocused ? 2.0 : 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: hasEnteredDigit
                          ? Text(
                              inputCodeString[digitItemIndex],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : isFieldCellFocused
                              ? Container(
                                  width: 2,
                                  height: 22,
                                  color: AppTheme.primaryColor,
                                )
                              : null,
                    );
                  }),
                );
              },
            ),
          ),
          SizedBox(
            height: 0,
            width: 0,
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _passengerOtpController,
                focusNode: _passengerOtpFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ),
          if (_onboardingErrorMessage != null) ...[
            const SizedBox(height: 20),
            _buildOnboardingErrorDisplayPanel(_onboardingErrorMessage!),
          ],
          const SizedBox(height: 32),
          if (_isProcessingRequest)
            const CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2.5,
            ),
          const SizedBox(height: 28),
          _secondsRemainingBeforeOtpResend > 0
              ? Text(
                  'Resend code in ${_secondsRemainingBeforeOtpResend}s',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                )
              : TextButton(
                  onPressed: _isProcessingRequest ? null : _resendOtpVerificationCode,
                  child: const Text(
                    'Resend code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildOnboardingProfileCompletionStepView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Introduce\nyourself',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Your name and phone let your driver find and contact you easily.',
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.primaryColor.withValues(alpha: 0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _buildOnboardingFieldLabel('Full name'),
          const SizedBox(height: 8),
          _buildOnboardingTextField(
            textController: _passengerNameController,
            placeholderHintText: 'e.g. Maria Santos',
            capitalizationType: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          _buildOnboardingFieldLabel('Phone number'),
          const SizedBox(height: 8),
          _buildOnboardingTextField(
            textController: _passengerPhoneController,
            placeholderHintText: '+63 912 345 6789',
            inputType: TextInputType.phone,
          ),
          if (_onboardingErrorMessage != null) ...[
            const SizedBox(height: 16),
            _buildOnboardingErrorDisplayPanel(_onboardingErrorMessage!),
          ],
          const SizedBox(height: 36),
          _buildOnboardingActionSubmitButton(
            buttonLabelText: 'Create Account',
            onActionPressed: _isProcessingRequest ? null : _submitPassengerProfileDetails,
            isRequestExecuting: _isProcessingRequest,
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingFieldLabel(String labelText) {
    return Text(
      labelText,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryColor,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildOnboardingTextField({
    required TextEditingController textController,
    required String placeholderHintText,
    TextInputType inputType = TextInputType.text,
    bool isObscured = false,
    Widget? suffixButton,
    TextCapitalization capitalizationType = TextCapitalization.none,
  }) {
    return TextField(
      controller: textController,
      keyboardType: inputType,
      obscureText: isObscured,
      textCapitalization: capitalizationType,
      style: const TextStyle(
        fontSize: 16,
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: placeholderHintText,
        hintStyle: TextStyle(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: suffixButton,
        filled: true,
        fillColor: AppTheme.primaryColor.withValues(alpha: 0.04),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingActionSubmitButton({
    required String buttonLabelText,
    required VoidCallback? onActionPressed,
    required bool isRequestExecuting,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onActionPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.neutralColor,
          disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isRequestExecuting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                buttonLabelText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
      ),
    );
  }

  Widget _buildOnboardingErrorDisplayPanel(String errorMessageText) {
    return Row(
      children: [
        const Icon(LucideIcons.circle_alert, size: 14, color: AppTheme.cancel),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            errorMessageText,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.cancel,
            ),
          ),
        ),
      ],
    );
  }
}
