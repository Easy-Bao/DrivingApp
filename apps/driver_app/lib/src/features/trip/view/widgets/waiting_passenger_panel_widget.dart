import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class WaitingPassengerPanelWidget extends StatelessWidget {
  final String pickup;
  final String dropoff;
  final String passengerName;
  final String waitFormatted;
  final double fare;
  final bool isStartingTrip;
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
    required this.unreadChatMessagesCount,
    required this.onStartTripPressed,
    required this.onCallPressed,
    required this.onChatPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSide),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
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
                      'Waiting $waitFormatted',
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
          const SizedBox(height: 12),
          _routeSummary(),
          const SizedBox(height: 10),
          _passengerSummary(),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _secondaryAction(
                  icon: LucideIcons.phone,
                  label: 'Call',
                  filled: true,
                  onPressed: onCallPressed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _secondaryAction(
                  icon: LucideIcons.message_circle,
                  label: 'Chat',
                  badgeCount: unreadChatMessagesCount,
                  onPressed: onChatPressed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isStartingTrip ? null : onStartTripPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: isStartingTrip
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(LucideIcons.play, size: 17),
                        SizedBox(width: 8),
                        Text('Start trip'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        children: [
          _addressRow(LucideIcons.circle_dot, 'Pickup', pickup),
          const Padding(
            padding: EdgeInsets.only(left: 6, top: 4, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 1,
                height: 10,
                child: ColoredBox(color: AppTheme.borderSide),
              ),
            ),
          ),
          _addressRow(LucideIcons.map_pin, 'Drop-off', dropoff),
        ],
      ),
    );
  }

  Widget _addressRow(IconData icon, String label, String address) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.tertiaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.tertiaryColor.withValues(alpha: 0.8),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                address,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _passengerSummary() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Row(
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
                const Text(
                  'Meet the passenger at pickup',
                  style: TextStyle(fontSize: 11, color: AppTheme.tertiaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _secondaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool filled = false,
    int badgeCount = 0,
  }) {
    final background = filled ? AppTheme.primaryColor : AppTheme.neutralColor;
    final foreground = filled ? Colors.white : AppTheme.primaryColor;
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
              Badge(
                isLabelVisible: badgeCount > 0,
                label: Text('$badgeCount'),
                backgroundColor: AppTheme.cancel,
                child: Icon(icon, color: foreground, size: 16),
              ),
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
