import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

class PickupNavigationPanelWidget extends StatelessWidget {
  final String pickup;
  final String dropoff;
  final String passengerName;
  final double distance;
  final double fare;
  final double sliderValue;
  final bool isConfirmingArrival;
  final int unreadChatMessagesCount;
  final ValueChanged<double> onSliderChanged;
  final VoidCallback onSliderCompleted;
  final VoidCallback onCallPressed;
  final VoidCallback onChatPressed;

  const PickupNavigationPanelWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.passengerName,
    required this.distance,
    required this.fare,
    required this.sliderValue,
    this.isConfirmingArrival = false,
    required this.unreadChatMessagesCount,
    required this.onSliderChanged,
    required this.onSliderCompleted,
    required this.onCallPressed,
    required this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.onSurface.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
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
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          CompactRouteTimelineWidget(pickup: pickup, dropoff: dropoff),
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
                      icon: const Icon(LucideIcons.message_circle),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _arrivalSlider(),
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
        borderRadius: BorderRadius.circular(16),
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
        ? context.colorScheme.onSurface
        : context.colorScheme.surfaceContainerHighest;
    final foreground = filled
        ? context.colorScheme.onPrimary
        : context.colorScheme.onSurface;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: filled
                ? null
                : Border.all(color: context.colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              const SizedBox(width: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const thumbSize = 52.0;
        final travel = (constraints.maxWidth - thumbSize)
            .clamp(0.0, double.infinity)
            .toDouble();
        return Container(
          height: 52,
          decoration: BoxDecoration(
            color: context.semanticColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Stack(
            children: [
              Center(
                child: Text(
                  isConfirmingArrival
                      ? 'Confirming arrival…'
                      : sliderValue > 0.8
                      ? 'Release to confirm'
                      : 'Slide when you arrive',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: context.semanticColors.success,
                  ),
                ),
              ),
              Positioned(
                left: travel * sliderValue,
                top: 0,
                child: GestureDetector(
                  onHorizontalDragUpdate: isConfirmingArrival || travel == 0
                      ? null
                      : (details) => onSliderChanged(
                          (sliderValue + details.delta.dx / travel)
                              .clamp(0.0, 1.0)
                              .toDouble(),
                        ),
                  onHorizontalDragEnd: isConfirmingArrival
                      ? null
                      : (_) {
                          if (sliderValue >= 0.85) {
                            onSliderCompleted();
                          } else {
                            onSliderChanged(0);
                          }
                        },
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      color: context.semanticColors.success,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isConfirmingArrival
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.semanticColors.onSuccess,
                              ),
                            )
                          : Icon(
                              LucideIcons.chevron_right,
                              color: context.semanticColors.onSuccess,
                              size: 22,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
