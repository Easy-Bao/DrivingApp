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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          backButton,
          if (bookingReference?.trim().isNotEmpty == true) ...[
            const SizedBox(width: 8),
            Flexible(
              child: TripReference(id: bookingReference!, compact: true),
            ),
            const SizedBox(width: 8),
          ],
          Row(mainAxisSize: MainAxisSize.min, children: actions),
        ],
      ),
    );
  }
}
