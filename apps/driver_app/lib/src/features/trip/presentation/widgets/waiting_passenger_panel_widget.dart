import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class WaitingPassengerPanelWidget extends StatelessWidget {
  final String pickup;
  final String dropoff;
  final String passengerName;
  final String waitFormatted;
  final double fare;
  final bool isStartingTrip;
  final bool includeStartTripButton;
  final int unreadChatMessagesCount;
  final VoidCallback onStartTripPressed;
  final VoidCallback onCallPressed;
  final VoidCallback onChatPressed;

  const WaitingPassengerPanelWidget({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.passengerName,
    required this.waitFormatted,
    required this.fare,
    this.isStartingTrip = false,
    this.includeStartTripButton = true,
    required this.unreadChatMessagesCount,
    required this.onStartTripPressed,
    required this.onCallPressed,
    required this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.semanticColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 13,
                    color: context.semanticColors.success,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Waiting For Passenger $waitFormatted',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: context.semanticColors.success,
                    ),
                  ),
                ],
              ),
            ),
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
        const SizedBox(height: 16),
        Divider(height: 1, color: context.colorScheme.outlineVariant),
        const SizedBox(height: 14),
        CompactRouteTimelineWidget(pickup: pickup, dropoff: dropoff),
        const SizedBox(height: 14),
        Divider(height: 1, color: context.colorScheme.outlineVariant),
        const SizedBox(height: 12),
        _passengerSummary(context),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _secondaryAction(
                context,
                icon: LucideIcons.phone,
                label: 'Call Passenger',
                filled: true,
                onPressed: onCallPressed,
              ),
            ),
            const SizedBox(width: 12),
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
        if (includeStartTripButton) ...[
          const SizedBox(height: 12),
          WaitingPassengerStartTripButton(
            isStartingTrip: isStartingTrip,
            onPressed: onStartTripPressed,
          ),
        ],
      ],
    );
  }

  Widget _passengerSummary(BuildContext context) {
    final meetingCopy = passengerName.trim().isEmpty || passengerName == '—'
        ? 'Meet The Passenger At Pickup'
        : 'Meet $passengerName At Pickup';
    return Row(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                passengerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                meetingCopy,
                style: TextStyle(
                  fontSize: 11,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _secondaryAction(
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
              Icon(icon, color: foreground, size: 16),
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
}

class WaitingPassengerStartTripButton extends StatelessWidget {
  final bool isStartingTrip;
  final VoidCallback onPressed;

  const WaitingPassengerStartTripButton({
    super.key,
    required this.isStartingTrip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isStartingTrip ? null : onPressed,
        style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
        child: isStartingTrip
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.colorScheme.onPrimary,
                ),
              )
            : const Text('Start Trip'),
      ),
    );
  }
}
