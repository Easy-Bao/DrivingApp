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
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            key: const ValueKey<String>('recent-activity-back-button'),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.arrow_left),
            tooltip: 'Back',
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Center(
                child: Text(title, style: context.textStyles.displayLarge),
              ),
            ),
          ),
          const SizedBox(width: 48, height: 48),
        ],
      );
    }

    return EasyRidePageHeader(title: title, subtitle: subtitle);
  }
}
