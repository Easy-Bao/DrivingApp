import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

class const ActiveRideHeader({
  super.key,
  required this.backButton,
  required this.actions,
  this.bookingReference,
  this.padding = EdgeInsets.zero,
}) extends StatelessWidget {
  final Widget backButton;
  final List<Widget> actions;
  final String? bookingReference;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          backButton,
          const Spacer(),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: context.colorScheme.surfaceContainerHighest,
              foregroundColor: context.colorScheme.onSurface,
            ),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              useSafeArea: true,
              showDragHandle: true,
              isScrollControlled: true,
              builder: (context) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Trip details', style: context.textStyles.titleLarge),
                    const SizedBox(height: 16),
                    if (bookingReference?.trim().isNotEmpty == true)
                      TripReference(id: bookingReference!),
                    if (actions.length > 1) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Report an issue',
                              style: context.textStyles.titleSmall,
                            ),
                          ),
                          ...actions.skip(1),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            child: const Text('Trip details'),
          ),
          const SizedBox(width: 8),
          if (actions.isNotEmpty) actions.first,
        ],
      ),
    );
  }
}
