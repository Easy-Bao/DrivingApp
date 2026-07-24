import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/signup_cubit.dart';
import 'package:passenger_app/src/features/auth/presentation/cubits/signup_state.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SignUpCubit>(
      create: (context) => Modular.get<SignUpCubit>(),
      child: const _SignupScreenContent(),
    );
  }
}

class _SignupScreenContent extends StatefulWidget {
  const _SignupScreenContent();

  @override
  State<_SignupScreenContent> createState() => _SignupScreenContentState();
}

class _SignupScreenContentState extends State<_SignupScreenContent> {
  final PageController _onboardingPageController = PageController();

  int _currentStepIndex = 0;

  final TextEditingController _passengerEmailController =
      TextEditingController();
  final TextEditingController _passengerPasswordController =
      TextEditingController();
  final TextEditingController _passengerNameController =
      TextEditingController();
  final TextEditingController _passengerPhoneController =
      TextEditingController();

  bool _isPasswordInputVisible = false;

  @override
  void dispose() {
    _onboardingPageController.dispose();
    _passengerEmailController.dispose();
    _passengerPasswordController.dispose();
    _passengerNameController.dispose();
    _passengerPhoneController.dispose();
    super.dispose();
  }

  void _advanceToNextOnboardingPage() {
    unawaited(
      _onboardingPageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      ),
    );
    setState(() {
      _currentStepIndex++;
    });
  }

  void _retreatToPreviousOnboardingPage() {
    if (_currentStepIndex == 0) {
      context.pop();
      return;
    }
    unawaited(
      _onboardingPageController.previousPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      ),
    );
    setState(() {
      _currentStepIndex--;
    });
  }

  Future<void> _submitEmailAndPassword(BuildContext context) async {
    FocusScope.of(context).unfocus();
    final email = _passengerEmailController.text.trim();
    final password = _passengerPasswordController.text;
    if (email.isEmpty || password.isEmpty) return;

    unawaited(
      BlocProvider.of<SignUpCubit>(context).registerPassenger(
        name: 'Passenger',
        email: email,
        phone: '',
        password: password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: _retreatToPreviousOnboardingPage,
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
        child: BlocConsumer<SignUpCubit, SignUpState>(
          listener: (context, state) {
            if (state is SignUpNeedsVerification) {
              unawaited(
                context
                    .pushNamed(
                      AuthRoutes.verifyOtp,
                      extra: {
                        'email': state.email,
                        'password': _passengerPasswordController.text,
                      },
                    )
                    .then((verified) {
                      if (verified == true && mounted) {
                        _advanceToNextOnboardingPage();
                      }
                    }),
              );
            } else if (state is SignUpSuccess) {
              _advanceToNextOnboardingPage();
            }
          },
          builder: (context, state) {
            final isLoading = state is SignUpLoading;
            final errorMessage = state is SignUpFailure
                ? state.errorMessage
                : null;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: List.generate(
                      2,
                      (index) => Expanded(
                        child: Container(
                          height: 4,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: index <= _currentStepIndex
                                ? AppTheme.primaryColor
                                : AppTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _onboardingPageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildEmailAndPasswordPage(
                        context,
                        isLoading,
                        errorMessage,
                      ),
                      _buildProfileSetupPage(context, isLoading, errorMessage),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmailAndPasswordPage(
    BuildContext context,
    bool isLoading,
    String? errorMessage,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your email and a strong password to get started.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                if (errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cancel.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      errorMessage,
                      style: const TextStyle(
                        color: AppTheme.cancel,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  controller: _passengerEmailController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    hintStyle: TextStyle(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsetsGeometry.only(left: 10),
                      child: Icon(LucideIcons.mail, size: 20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  obscureText: !_isPasswordInputVisible,
                  controller: _passengerPasswordController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: TextStyle(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsetsGeometry.only(left: 10),
                      child: Icon(LucideIcons.lock, size: 20),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordInputVisible
                            ? LucideIcons.eye
                            : LucideIcons.eye_off,
                        size: 20,
                      ),
                      onPressed: () => setState(
                        () =>
                            _isPasswordInputVisible = !_isPasswordInputVisible,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () => _submitEmailAndPassword(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.neutralColor,
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
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
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSetupPage(
    BuildContext context,
    bool isLoading,
    String? errorMessage,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Profile Details',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your profile to start booking rides.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _passengerNameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    prefixIcon: const Padding(
                      padding: EdgeInsetsGeometry.only(left: 10),
                      child: Icon(LucideIcons.user, size: 20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passengerPhoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: 'Phone Number',
                    prefixIcon: const Padding(
                      padding: EdgeInsetsGeometry.only(left: 10),
                      child: Icon(LucideIcons.phone, size: 20),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: BorderSide(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(32),
                      borderSide: const BorderSide(
                        color: AppTheme.primaryColor,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    unawaited(context.pushNamed(HomeRoutes.home));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppTheme.neutralColor,
                    minimumSize: const Size.fromHeight(60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Complete Setup',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
