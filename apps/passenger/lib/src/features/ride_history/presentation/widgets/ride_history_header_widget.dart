import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class const RideHistoryHeaderWidget({
  this.subtitle,
  this.title = 'Activity',
  this.showBackButton = false,
  super.key,
}) extends StatelessWidget {
  final String? subtitle;
  final String title;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    if (showBackButton) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            IconButton(
              key: const ValueKey<String>('recent-activity-back-button'),
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              icon: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: context.colorScheme.outlineVariant,
                    width: 0.8,
                  ),
                ),
                child: Icon(
                  LucideIcons.arrow_left,
                  size: 19,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 40, height: 40),
          ],
        ),
      );
    }

    return EasyRidePageHeader(title: title, subtitle: subtitle);
  }
}
