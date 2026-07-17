import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:http/http.dart' as http;
import 'package:passenger_app/src/features/auth/auth_routes.dart';
import 'package:passenger_app/src/features/trip_booking/trip_routes.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:session_service/session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool isChecked = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

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
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Image.asset(
          'assets/logo/applogo.png',
          height: 150,
          fit: BoxFit.cover,
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Log in to continue your journey.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: 'Email',
                        errorText: _emailError,
                        errorStyle: const TextStyle(color: AppTheme.cancel),
                        prefixIcon: const Padding(
                          padding: EdgeInsetsGeometry.only(left: 10),
                          child: Icon(LucideIcons.mail, size: 20),
                        ),
                        filled: false,
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                          borderSide: const BorderSide(color: AppTheme.cancel),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                          borderSide: const BorderSide(
                            color: AppTheme.cancel,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      obscureText: !_isPasswordVisible,
                      controller: _passwordController,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        errorText: _passwordError,
                        errorStyle: const TextStyle(color: AppTheme.cancel),
                        prefixIcon: const Padding(
                          padding: EdgeInsetsGeometry.only(left: 10),
                          child: Icon(LucideIcons.lock, size: 20),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? LucideIcons.eye
                                : LucideIcons.eye_off,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                        ),
                        filled: false,
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
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                          borderSide: const BorderSide(color: AppTheme.cancel),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(32),
                          borderSide: const BorderSide(
                            color: AppTheme.cancel,
                            width: 1.5,
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
                              activeColor: AppTheme.primaryColor,
                              onChanged: (bool? val) {
                                setState(() {
                                  isChecked = val!;
                                });
                              },
                            ),
                            const Text(
                              'Remember me',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            unawaited(context.pushNamed(AuthRoutes.forgotPassword));
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.neutralColor,
                        minimumSize: const Size.fromHeight(60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: AppTheme.neutralColor,
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.4,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton(
                      onPressed: () {
                        context.goNamed('DriverDashboard');
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        side: BorderSide(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset('assets/icons/google.png', height: 20),
                          const SizedBox(width: 12),
                          const Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: TextStyle(
                            color: AppTheme.primaryColor.withValues(alpha: 0.6),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            unawaited(context.pushNamed('Signup'));
                          },
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
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

  Map<String, dynamic> _parseErrorJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    bool hasError = false;
    if (email.isEmpty) {
      _emailError = 'Please enter email';
      hasError = true;
    } else if (!email.contains('@')) {
      _emailError = 'Please enter a valid email';
      hasError = true;
    }

    if (password.isEmpty) {
      _passwordError = 'Please enter password';
      hasError = true;
    }

    if (hasError) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Modular.get<PassengerApiService>().baseUrl.replace(
        path: '/passengers/login',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['token'] as String;
        final passenger = data['passenger'] as Map<String, dynamic>;

        final sessionService = Modular.get<SecureSessionService>();
        await sessionService.writeAuthToken(token);
        await sessionService.writePassengerId(passenger['id'] as String);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', token);
        await prefs.setString('passenger_id', passenger['id'] as String);
        await prefs.setString('passenger_name', passenger['name'] as String);
        await prefs.setString('passenger_phone', passenger['phone'] as String);
        await prefs.setString('passenger_email', passenger['email'] as String);

        if (!mounted) return;
        unawaited(context.pushNamed(TripRoutes.passengerHome));
      } else {
        final errorData = _parseErrorJson(response.body);
        final errorMsg = errorData['error'] ?? 'Login failed';
        if (errorData['needs_verification'] == true) {
          final verifyEmail = errorData['email'] ?? email;
          unawaited(context.pushNamed(AuthRoutes.verifyOtp, queryParameters: {'email': verifyEmail}));
        } else {
          final cleanMsg = _cleanErrorMessage(errorMsg);
          setState(() {
            if (cleanMsg.toLowerCase().contains('password')) {
              _passwordError = cleanMsg;
              _emailError = null;
            } else {
              _emailError = cleanMsg;
              _passwordError = null;
            }
          });
        }
      }
    } catch (error) {
      if (!mounted) return;
      final cleanMsg = _cleanErrorMessage(error);
      setState(() {
        if (cleanMsg.toLowerCase().contains('password')) {
          _passwordError = cleanMsg;
          _emailError = null;
        } else {
          _emailError = cleanMsg;
          _passwordError = null;
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _cleanErrorMessage(dynamic error) {
    final String errorStr = error.toString();
    if (errorStr.contains('No passenger registered with this email') || 
        errorStr.contains('passenger not found') ||
        errorStr.contains('user not found') ||
        errorStr.contains('not found')) {
      return 'No account found with this email address.';
    }
    if (errorStr.contains('invalid password') || 
        errorStr.contains('incorrect password') || 
        errorStr.contains('password incorrect') ||
        errorStr.contains('invalid credentials')) {
      return 'Incorrect password. Please try again.';
    }
    if (errorStr.contains('"error":')) {
      try {
        final startIdx = errorStr.indexOf('{');
        if (startIdx != -1) {
          final jsonPart = errorStr.substring(startIdx);
          final Map<String, dynamic> data = jsonDecode(jsonPart);
          if (data.containsKey('error')) {
            final String msg = data['error'] as String;
            if (msg.contains('No passenger registered with this email') ||
                msg.contains('passenger not found') ||
                msg.contains('user not found') ||
                msg.contains('not found')) {
              return 'No account found with this email address.';
            }
            if (msg.contains('invalid password') ||
                msg.contains('incorrect password') ||
                msg.contains('password incorrect') ||
                msg.contains('invalid credentials')) {
              return 'Incorrect password. Please try again.';
            }
            return msg;
          }
        }
      } catch (_) {}
    }
    return 'Connection failed. Please check your internet connection.';
  }
}
