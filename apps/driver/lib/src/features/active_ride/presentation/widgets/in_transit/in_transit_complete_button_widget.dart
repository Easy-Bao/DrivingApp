import 'package:flutter/material.dart';
import 'package:design_system/design_system.dart';

class const InTransitCompleteButtonWidget({
  super.key,
  required this.onCompleteTripPressed,
  this.isCompletingTrip = false,
}) extends StatelessWidget {
  final VoidCallback onCompleteTripPressed;
  final bool isCompletingTrip;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCompletingTrip ? null : onCompleteTripPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: context.semanticColors.success,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: isCompletingTrip
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: context.semanticColors.onSuccess,
                  ),
                )
              : Text(
                  'Complete Trip',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.semanticColors.onSuccess,
                  ),
                ),
        ),
      ),
    );
  }
}
