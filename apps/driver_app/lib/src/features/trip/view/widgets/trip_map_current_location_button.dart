import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class TripMapCurrentLocationButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const TripMapCurrentLocationButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      elevation: 3,
      shadowColor: AppTheme.primaryColor.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(
            LucideIcons.locate_fixed,
            size: 21,
            color: onPressed == null
                ? AppTheme.unselectedItemColor
                : AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}
