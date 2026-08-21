import 'package:driver_app/src/core/theme/app_theme.dart';

import 'package:flutter/material.dart';

class InTransitCompleteButtonWidget extends StatelessWidget {
  final VoidCallback onCompleteTripPressed;
  final bool isCompletingTrip;

  const InTransitCompleteButtonWidget({
    super.key,
    required this.onCompleteTripPressed,
    this.isCompletingTrip = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isCompletingTrip ? null : onCompleteTripPressed,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.complete,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: isCompletingTrip
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Complete Trip',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}
