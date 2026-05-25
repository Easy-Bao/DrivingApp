import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _isPasswordVisible = false;
  bool isChecked = false;

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
          "assets/logo/applogo.png",
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
                      "Create an account",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign up to continue your journey.",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: "Email",
                        prefixIcon: Padding(
                          padding: EdgeInsetsGeometry.only(left: 10),
                          child: const Icon(LucideIcons.mail, size: 20),
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: "Password",
                        prefixIcon: Padding(
                          padding: EdgeInsetsGeometry.only(left: 10),
                          child: const Icon(LucideIcons.lock, size: 20),
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      obscureText: !_isPasswordVisible,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        hintText: "Confirm Password",
                        prefixIcon: Padding(
                          padding: EdgeInsetsGeometry.only(left: 10),
                          child: const Icon(LucideIcons.lock, size: 20),
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
                              "Remember me",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {},
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
                        "Sign up",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account?",
                          style: TextStyle(
                            color: AppTheme.primaryColor.withValues(alpha: 0.6),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            context.pushNamed("Signin");
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
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
}
