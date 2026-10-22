import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class RidePanelHeader extends StatelessWidget {
  const RidePanelHeader({
    super.key,
    required this.title,
    required this.details,
    required this.onClose,
    this.closeKey,
  });

  final String title;
  final String details;
  final VoidCallback onClose;
  final Key? closeKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          key: closeKey,
          onPressed: onClose,
          tooltip: 'Back to trip summary',
          constraints: const BoxConstraints.tightFor(
            width: AppSize.minimumTouchTarget,
            height: AppSize.minimumTouchTarget,
          ),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            backgroundColor: context.colorScheme.surfaceContainerHighest,
            shape: const CircleBorder(),
          ),
          icon: Icon(
            LucideIcons.chevron_down,
            color: context.colorScheme.onSurface,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                details,
                style: TextStyle(
                  color: context.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
