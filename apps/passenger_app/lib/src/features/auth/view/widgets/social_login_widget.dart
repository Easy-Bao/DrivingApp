import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

class SocialLoginWidget extends StatelessWidget {
  final VoidCallback onGoogleTap;
  final String label;
  final String heroTag;

  const SocialLoginWidget({
    super.key,
    required this.onGoogleTap,
    this.label = 'Continue with Google',
    this.heroTag = 'auth_google_button',
  });

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
        Hero(
          tag: heroTag,
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
                  borderRadius: BorderRadius.circular(36),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/icons/google.png',
                    package: 'shared_ui',
                    width: 22,
                    height: 22,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.g_mobiledata,
                      size: 24,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
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
