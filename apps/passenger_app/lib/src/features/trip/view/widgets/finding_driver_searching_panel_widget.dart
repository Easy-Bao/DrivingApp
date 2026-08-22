import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:shared_core/shared_core.dart';

class FindingDriverSearchingPanelWidget extends StatelessWidget {
  final String message;
  final String rideType;
  final double fare;
  final PlaceModel destination;
  final String? pickupAddress;
  final Animation<double> dotAnimation;
  final VoidCallback onCancelPressed;
  final bool isCanceling;

  const FindingDriverSearchingPanelWidget({
    super.key,
    required this.message,
    required this.rideType,
    required this.fare,
    required this.destination,
    this.pickupAddress,
    required this.dotAnimation,
    required this.onCancelPressed,
    this.isCanceling = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.borderSide,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: dotAnimation,
            builder: (ctx, _) {
              final dots = '.' * (1 + (dotAnimation.value * 3).floor());
              return Text(
                '$message$dots',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            pickupAddress != null
                ? 'Request Sent. Your Driver Is Reviewing Your Ride Request.'
                : 'Looking For $rideType Drivers Nearby...',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.neutralColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderSide),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.map_pin,
                      size: 16,
                      color: AppTheme.tertiaryColor,
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 160,
                      child: Text(
                        destination.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  '₱${fare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: isCanceling ? null : onCancelPressed,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.cancel.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(32),
              ),
              child: isCanceling
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.cancel,
                      ),
                    )
                  : const Text(
                      'Cancel Search',
                      style: TextStyle(
                        color: AppTheme.cancel,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
