import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/ride_confirmation_slider.dart';

class const PickupNavigationPanel({
  super.key,
  required this.pickup,
  required this.dropoff,
  required this.passengerName,
  required this.distance,
  required this.fare,
  required this.sliderValue,
  this.isConfirmingArrival = false,
  this.isCancelling = false,
  required this.unreadChatMessagesCount,
  required this.onSliderChanged,
  required this.onSliderCompleted,
  required this.onCancelPressed,
  required this.onCallPressed,
  required this.onChatPressed,
}) extends StatelessWidget {
  final String pickup;
  final String dropoff;
  final String passengerName;
  final double distance;
  final double fare;
  final double sliderValue;
  final bool isConfirmingArrival;
  final bool isCancelling;
  final int unreadChatMessagesCount;
  final ValueChanged<double> onSliderChanged;
  final VoidCallback onSliderCompleted;
  final VoidCallback onCancelPressed;
  final VoidCallback onCallPressed;
  final VoidCallback onChatPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(EasyRideRadius.sheet),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        EasyRideSpacing.lg,
        10,
        EasyRideSpacing.lg,
        EasyRideSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: context.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statusPill(context),
              const Spacer(),
              Text(
                formatPesoAmount(fare),
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CompactRouteTimeline(pickup: pickup, dropoff: dropoff),
          const SizedBox(height: 10),
          _passengerRow(context),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  context,
                  icon: LucideIcons.phone,
                  label: 'Call Passenger',
                  filled: true,
                  onPressed: onCallPressed,
                ),
              ),
              const SizedBox(width: 10),
              Semantics(
                button: true,
                label: 'Chat with passenger',
                child: Badge(
                  isLabelVisible: unreadChatMessagesCount > 0,
                  label: Text('$unreadChatMessagesCount'),
                  backgroundColor: context.colorScheme.error,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.colorScheme.outlineVariant,
                      ),
                    ),
                    child: IconButton(
                      tooltip: 'Chat with passenger',
                      onPressed: onChatPressed,
                      constraints: const BoxConstraints(
                        minWidth: EasyRideSize.minimumTouchTarget,
                        minHeight: EasyRideSize.minimumTouchTarget,
                      ),
                      icon: const Icon(LucideIcons.message_circle),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _arrivalSlider(),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: EasyRideSize.minimumTouchTarget,
            child: OutlinedButton.icon(
              onPressed: isCancelling ? null : onCancelPressed,
              icon: isCancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.circle_x),
              label: Text(isCancelling ? 'Cancelling…' : 'Cancel ride'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusPill(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.semanticColors.success.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.navigation,
            size: 13,
            color: context.semanticColors.success,
          ),
          SizedBox(width: 6),
          Text(
            'Heading To Passenger',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: context.semanticColors.success,
            ),
          ),
        ],
      ),
    );
  }

  Widget _passengerRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.user_round,
              size: 17,
              color: context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              passengerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            DistanceFormatter.fromKilometers(distance),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: context.colorScheme.onSurfaceVariant,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool filled = false,
  }) {
    final background = filled
        ? context.colorScheme.primary
        : context.colorScheme.surface;
    final foreground = filled
        ? context.colorScheme.onPrimary
        : context.colorScheme.onSurface;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(EasyRideRadius.lg),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        child: Container(
          height: EasyRideSize.minimumTouchTarget,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(EasyRideRadius.lg),
            border: filled
                ? null
                : Border.all(color: context.colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 8),
              Text(
                label,
                style: context.textStyles.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _arrivalSlider() {
    return RideConfirmationSlider(
      progress: sliderValue,
      label: 'Slide when you arrive',
      releaseLabel: 'Release to confirm',
      processingLabel: 'Confirming arrival…',
      hint: 'Swipe right to confirm arrival.',
      isProcessing: isConfirmingArrival,
      onProgressChanged: onSliderChanged,
      onConfirmed: onSliderCompleted,
    );
  }
}
