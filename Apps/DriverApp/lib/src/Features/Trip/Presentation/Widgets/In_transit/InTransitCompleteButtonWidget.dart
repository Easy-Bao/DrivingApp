import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

class InTransitCompleteButtonWidget extends StatelessWidget {
  final VoidCallback onCompleteTripPressed;

  const InTransitCompleteButtonWidget({
    super.key,
    required this.onCompleteTripPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCompleteTripPressed,
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
        child: const Center(
          child: Text(
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
