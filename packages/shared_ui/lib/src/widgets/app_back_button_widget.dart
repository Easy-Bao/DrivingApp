import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

/// A consistent, accessible back affordance for map and detail surfaces.
class AppBackButtonWidget extends StatelessWidget {
  const AppBackButtonWidget({
    super.key,
    required this.onPressed,
    this.showSurface = true,
  });

  const AppBackButtonWidget.plain({super.key, required this.onPressed})
      : showSurface = false;

  final VoidCallback onPressed;
  final bool showSurface;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final iconButton = IconButton(
      onPressed: onPressed,
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      padding: EdgeInsets.zero,
      icon: Icon(
        LucideIcons.arrow_left,
        color: colors.onSurface,
        size: 20,
      ),
    );
    if (!showSurface) return iconButton;

    return SizedBox(
      width: 46,
      height: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: iconButton,
      ),
    );
  }
}
