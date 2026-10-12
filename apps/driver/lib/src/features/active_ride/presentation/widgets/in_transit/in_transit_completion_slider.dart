import 'package:driver/src/features/active_ride/presentation/widgets/ride_confirmation_slider.dart';
import 'package:flutter/material.dart';

class const InTransitCompletionSlider({
  super.key,
  required this.progress,
  required this.onProgressChanged,
  required this.onCompleteTripPressed,
  this.isCompletingTrip = false,
}) extends StatelessWidget {
  final double progress;
  final ValueChanged<double> onProgressChanged;
  final VoidCallback onCompleteTripPressed;
  final bool isCompletingTrip;

  @override
  Widget build(BuildContext context) {
    return RideConfirmationSlider(
      progress: progress,
      label: 'Slide to complete trip',
      releaseLabel: 'Release to complete',
      processingLabel: 'Completing trip…',
      hint: 'Swipe right to complete the trip.',
      isProcessing: isCompletingTrip,
      onProgressChanged: onProgressChanged,
      onConfirmed: onCompleteTripPressed,
    );
  }
}
