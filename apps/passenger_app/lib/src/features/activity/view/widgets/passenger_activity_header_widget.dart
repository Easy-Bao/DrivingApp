import 'package:flutter/material.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

class PassengerActivityHeaderWidget extends StatelessWidget {
  final String subtitle;

  const PassengerActivityHeaderWidget({required this.subtitle, super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity',
          style: textTheme.headlineMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(
            color: AppTheme.tertiaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
