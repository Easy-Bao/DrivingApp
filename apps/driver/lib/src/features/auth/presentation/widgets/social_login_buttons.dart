import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class const SocialLoginButtons({
  super.key,
  required this.onGoogleTap,
  this.label = 'Continue with Google',
}) extends StatelessWidget {
  final VoidCallback onGoogleTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: context.colorScheme.onSurface.withValues(alpha: 0.15),
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: context.colorScheme.onSurface.withValues(alpha: 0.15),
                thickness: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Material(
          child: Material(
            type: MaterialType.transparency,
            child: OutlinedButton(
              onPressed: onGoogleTap,
              style: OutlinedButton.styleFrom(
                backgroundColor: context.colorScheme.surface,
                minimumSize: const Size.fromHeight(56),
                side: BorderSide(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(EasyRideRadius.lg),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const GoogleLogo(),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

typedef SocialLoginWidget = SocialLoginButtons;
