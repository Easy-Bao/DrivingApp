import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
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
                color: AppTheme.complete.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 13,
                    color: AppTheme.complete,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Waiting For Passenger $waitFormatted',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.complete,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              '₱${fare.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppTheme.borderSide),
        const SizedBox(height: 14),
        CompactRouteTimelineWidget(pickup: pickup, dropoff: dropoff),
        const SizedBox(height: 14),
        const Divider(height: 1, color: AppTheme.borderSide),
        const SizedBox(height: 12),
        _passengerSummary(),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _secondaryAction(
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
                backgroundColor: AppTheme.cancel,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.interactiveSurface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.borderSide),
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

  Widget _passengerSummary() {
    final meetingCopy = passengerName.trim().isEmpty || passengerName == '—'
        ? 'Meet The Passenger At Pickup'
        : 'Meet $passengerName At Pickup';
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppTheme.secondarySurface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.user_round,
            size: 17,
            color: AppTheme.primaryColor,
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
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                meetingCopy,
                style: TextStyle(fontSize: 11, color: AppTheme.tertiaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _secondaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool filled = false,
  }) {
    final background = filled ? AppTheme.primaryColor : AppTheme.neutralColor;
    final foreground = filled
        ? AppTheme.activeControlForeground
        : AppTheme.primaryColor;
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
            border: filled ? null : Border.all(color: AppTheme.borderSide),
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
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.surface,
                ),
              )
            : const Text('Start Trip'),
      ),
    );
  }
}
