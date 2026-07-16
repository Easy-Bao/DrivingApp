import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/di/service_locator.dart';
import 'package:passenger_app/src/core/services/passenger_api_service.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/core/themes/app_themes.dart';

class EmailOnboardingScreen extends StatefulWidget {
  const EmailOnboardingScreen({super.key});

  @override
  State<EmailOnboardingScreen> createState() => _EmailOnboardingScreenState();
}

class _EmailOnboardingScreenState extends State<EmailOnboardingScreen> {
  final PageController _pageController = PageController();

  int _currentPage = 0;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  bool _passwordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  String _pendingEmail = '';
  String _pendingToken = '';
  String _pendingPassengerId = '';

  Timer? _resendTimer;
  int _resendSecondsRemaining = 60;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpDigitChanged);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _otpFocusNode.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _advancePage() {
    unawaited(_pageController.nextPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    ));
    setState(() {
      _currentPage++;
      _errorMessage = null;
    });
  }

  void _retreatPage() {
    if (_currentPage == 0) {
      context.pop();
      return;
    }
    unawaited(_pageController.previousPage(
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeInOut,
    ));
    setState(() {
      _currentPage--;
      _errorMessage = null;
    });
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsRemaining = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _resendSecondsRemaining--;
        if (_resendSecondsRemaining <= 0) timer.cancel();
      });
    });
  }

  Future<void> _submitEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailValid = RegExp(r'^[\w\-.]+@[\w\-]+\.\w{2,}$').hasMatch(email);
    if (!emailValid) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await getIt<PassengerApiService>().registerEmail(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result != null && result['needs_verification'] == true) {
        _pendingEmail = email;
        _otpController.clear();
        _startResendCountdown();
        _advancePage();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _otpFocusNode.requestFocus();
        });
      } else {
        setState(() => _errorMessage = 'Unexpected response. Please try again.');
      }
    } catch (error) {
      if (!mounted) return;
      final message = error.toString().contains('already registered')
          ? 'This email is already registered. Try signing in instead.'
          : 'Something went wrong. Please try again.';
      setState(() => _errorMessage = message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onOtpDigitChanged() {
    if (_otpController.text.length == 6 && !_isLoading) {
      unawaited(_submitOtp(_otpController.text));
    }
  }

  Future<void> _submitOtp(String code) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await getIt<PassengerApiService>().verifyEmailOtp(
        email: _pendingEmail,
        code: code,
      );

      if (!mounted) return;

      if (result != null && result['token'] != null) {
        _pendingToken = result['token'] as String;
        _pendingPassengerId =
            (result['passenger'] as Map<String, dynamic>?)?['id'] as String? ??
                '';
        _advancePage();
      } else {
        _otpController.clear();
        setState(() => _errorMessage = 'Invalid or expired code. Try again.');
      }
    } catch (error) {
      if (!mounted) return;
      _otpController.clear();
      setState(() => _errorMessage = 'Verification failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendSecondsRemaining > 0) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await getIt<PassengerApiService>().registerEmail(
        email: _pendingEmail,
        password: _passwordController.text,
      );
      if (!mounted) return;
      _startResendCountdown();
      _otpController.clear();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitProfile() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name.');
      return;
    }
    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter your phone number.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await getIt<PassengerApiService>().completeProfile(
        name: name,
        phone: phone,
        token: _pendingToken,
      );

      if (!mounted) return;

      if (result != null) {
        final session = getIt<SecureSessionService>();
        await session.writeAuthToken(_pendingToken);
        if (_pendingPassengerId.isNotEmpty) {
          await session.writePassengerId(_pendingPassengerId);
        }
        _advancePage();
      } else {
        setState(() => _errorMessage = 'Could not save profile. Please try again.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _requestLocationAndProceed() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        await Geolocator.requestPermission();
      }
    } finally {
      if (mounted) context.goNamed('PassengerHome');
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
              _buildTopBar(),
              _buildStepIndicator(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildEmailPasswordPage(),
                    _buildOtpPage(),
                    _buildProfilePage(),
                    _buildLocationPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: _retreatPage,
            icon: const Icon(
              LucideIcons.chevron_left,
              color: AppTheme.primaryColor,
              size: 20,
            ),
            label: Text(
              _currentPage == 0 ? 'Back' : 'Previous',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    const totalSteps = 4;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Row(
        children: List.generate(totalSteps, (stepIndex) {
          final isComplete = stepIndex < _currentPage;
          final isCurrent = stepIndex == _currentPage;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: stepIndex < totalSteps - 1 ? 6 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: (isComplete || isCurrent)
                      ? AppTheme.primaryColor
                      : AppTheme.primaryColor.withValues(alpha: 0.12),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmailPasswordPage() {
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
          _buildLabel('Email address'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _emailController,
            hintText: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 20),
          _buildLabel('Password'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _passwordController,
            hintText: 'At least 8 characters',
            obscureText: !_passwordVisible,
            suffix: IconButton(
              icon: Icon(
                _passwordVisible ? LucideIcons.eye_off : LucideIcons.eye,
                size: 18,
                color: AppTheme.primaryColor.withValues(alpha: 0.4),
              ),
              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorText(_errorMessage!),
          ],
          const SizedBox(height: 36),
          _buildPrimaryButton(
            label: 'Continue',
            onPressed: _isLoading ? null : _submitEmailPassword,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 20),
          Center(
            child: TextButton(
              onPressed: () => context.goNamed('Signin'),
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

  Widget _buildOtpPage() {
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
            'We sent a 6-digit code to\n$_pendingEmail',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.primaryColor.withValues(alpha: 0.55),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: () => _otpFocusNode.requestFocus(),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _otpController,
              builder: (context, value, _) {
                final code = value.text;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (digitIndex) {
                    final hasDigit = code.length > digitIndex;
                    final isFocused =
                        code.length == digitIndex && _otpFocusNode.hasFocus;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 46,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: hasDigit
                            ? AppTheme.primaryColor.withValues(alpha: 0.06)
                            : Colors.transparent,
                        border: Border.all(
                          color: _errorMessage != null
                              ? AppTheme.cancel
                              : isFocused
                                  ? AppTheme.primaryColor
                                  : AppTheme.primaryColor.withValues(alpha: 0.16),
                          width: isFocused ? 2.0 : 1.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: hasDigit
                          ? Text(
                              code[digitIndex],
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : isFocused
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
                controller: _otpController,
                focusNode: _otpFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
                autofocus: true,
                decoration: const InputDecoration(counterText: ''),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            _buildErrorText(_errorMessage!),
          ],
          const SizedBox(height: 32),
          if (_isLoading)
            const CircularProgressIndicator(
              color: AppTheme.primaryColor,
              strokeWidth: 2.5,
            ),
          const SizedBox(height: 28),
          _resendSecondsRemaining > 0
              ? Text(
                  'Resend code in ${_resendSecondsRemaining}s',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                )
              : TextButton(
                  onPressed: _isLoading ? null : _resendOtp,
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

  Widget _buildProfilePage() {
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
          _buildLabel('Full name'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _nameController,
            hintText: 'e.g. Maria Santos',
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 20),
          _buildLabel('Phone number'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _phoneController,
            hintText: '+63 912 345 6789',
            keyboardType: TextInputType.phone,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            _buildErrorText(_errorMessage!),
          ],
          const SizedBox(height: 36),
          _buildPrimaryButton(
            label: 'Create Account',
            onPressed: _isLoading ? null : _submitProfile,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.map_pin,
                    size: 56,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Enable location\naccess',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Enable location to find nearby rides, get accurate pick-up ETAs, and map your route easily.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.primaryColor.withValues(alpha: 0.55),
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              _buildPrimaryButton(
                label: 'Enable Location',
                onPressed: _requestLocationAndProceed,
                isLoading: false,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.goNamed('PassengerHome'),
                child: Text(
                  "I'll enter my address manually",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.primaryColor,
        letterSpacing: 0.4,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffix,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      style: const TextStyle(
        fontSize: 16,
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppTheme.primaryColor.withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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

  Widget _buildPrimaryButton({
    required String label,
    required VoidCallback? onPressed,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: AppTheme.neutralColor,
          disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
      ),
    );
  }

  Widget _buildErrorText(String message) {
    return Row(
      children: [
        const Icon(LucideIcons.circle_alert, size: 14, color: AppTheme.cancel),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            message,
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
