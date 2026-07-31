import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/shared_ui.dart';

class TrackDriverPanelWidget extends StatelessWidget {
  final RideHistoryModel ride;
  final String statusTitle;
  final String statusSubtitle;
  final String etaText;
  final int unreadChatMessagesCount;
  final VoidCallback onCallDriverPressed;
  final VoidCallback onChatDriverPressed;
  final VoidCallback onCancelTripPressed;

  const TrackDriverPanelWidget({
    super.key,
    required this.ride,
    required this.statusTitle,
    required this.statusSubtitle,
    required this.etaText,
    required this.unreadChatMessagesCount,
    required this.onCallDriverPressed,
    required this.onChatDriverPressed,
    required this.onCancelTripPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: PassengerTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: PassengerTheme.borderSide),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: PassengerTheme.darkSlate,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: PassengerTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusSubtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: PassengerTheme.slate,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: PassengerTheme.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: PassengerTheme.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  etaText,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: PassengerTheme.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PassengerTheme.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: PassengerTheme.borderSide),
            ),
            child: Row(
              children: [
                const AppNetworkImageWidget(
                  imageUrl: null,
                  width: 50,
                  height: 50,
                  fallbackIcon: LucideIcons.user,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.driverName.isNotEmpty
                            ? ride.driverName
                            : 'Driver',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: PassengerTheme.accent,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ride.vehicleType} • ${ride.vehiclePlate}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: PassengerTheme.mutedSand,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: LucideIcons.phone,
                  label: 'Call',
                  backgroundColor: PassengerTheme.accent,
                  foregroundColor: PassengerTheme.background,
                  onTap: onCallDriverPressed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: LucideIcons.message_circle,
                  label: 'Chat',
                  backgroundColor: PassengerTheme.background,
                  foregroundColor: PassengerTheme.accent,
                  badgeCount: unreadChatMessagesCount,
                  onTap: onChatDriverPressed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onCancelTripPressed,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: PassengerTheme.cancel.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: PassengerTheme.cancel.withValues(alpha: 0.3)),
              ),
              child: const Text(
                'Cancel Trip',
                style: TextStyle(
                  color: PassengerTheme.cancel,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    required VoidCallback onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(23),
          border: backgroundColor == PassengerTheme.background
              ? Border.all(color: PassengerTheme.borderSide)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              label: Text('$badgeCount'),
              isLabelVisible: badgeCount > 0,
              backgroundColor: PassengerTheme.cancel,
              child: Icon(icon, color: foregroundColor, size: 16),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
