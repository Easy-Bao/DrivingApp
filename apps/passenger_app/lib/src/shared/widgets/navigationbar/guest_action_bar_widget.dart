import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

class GuestActionBarWidget extends StatelessWidget {
  final VoidCallback onSignUp;
  final VoidCallback onSignIn;

  const GuestActionBarWidget({
    super.key,
    required this.onSignUp,
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderSide),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          const Expanded(
            child: Row(
              children: [
                Icon(
                  LucideIcons.sparkles,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Sign in to book rides',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onSignIn,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.borderSide),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text('Log in'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: onSignUp,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            child: const Text('Sign up'),
          ),
        ],
      ),
    );
  }
}
