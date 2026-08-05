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
        height: 68,
        decoration: BoxDecoration(
          color: AppTheme.complete,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: AppTheme.complete.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Center(
          child: isCompletingTrip
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'COMPLETE TRIP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
        ),
      ),
    );
  }
}
