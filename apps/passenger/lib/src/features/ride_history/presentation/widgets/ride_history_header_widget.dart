import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class const RideHistoryHeaderWidget({required this.subtitle, super.key})
    extends StatelessWidget {
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity',
          style: textTheme.headlineLarge?.copyWith(
            color: context.colorScheme.onSurface,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
