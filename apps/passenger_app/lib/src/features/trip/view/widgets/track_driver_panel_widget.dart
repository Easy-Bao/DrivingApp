import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

class TrackDriverPanelWidget extends StatelessWidget {
  final RideHistoryModel ride;
  final String statusTitle;
  final String statusSubtitle;
  final String etaText;
  final String? driverName;
  final String? vehicleSummary;
  final int unreadChatMessagesCount;
  final bool isCancellingTrip;
  final VoidCallback onCallDriverPressed;
  final VoidCallback onChatDriverPressed;
  final VoidCallback onCancelTripPressed;

  const TrackDriverPanelWidget({
    super.key,
    required this.ride,
    required this.statusTitle,
    required this.statusSubtitle,
    required this.etaText,
    this.driverName,
    this.vehicleSummary,
    required this.unreadChatMessagesCount,
    this.isCancellingTrip = false,
    required this.onCallDriverPressed,
    required this.onChatDriverPressed,
    required this.onCancelTripPressed,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedDriverName = driverName?.trim().isNotEmpty == true
        ? driverName!.trim()
        : ride.displayDriverName;
    final resolvedVehicleSummary = vehicleSummary?.trim().isNotEmpty == true
        ? vehicleSummary!.trim()
        : ride.displayVehicleSummary;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: AppTheme.borderSide),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderSide,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
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
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      statusSubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.tertiaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  etaText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.neutralColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderSide),
            ),
            child: Row(
              children: [
                const AppNetworkImageWidget(
                  imageUrl: null,
                  width: 38,
                  height: 38,
                  fallbackIcon: LucideIcons.user,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Driver',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.tertiaryColor,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        resolvedDriverName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        resolvedVehicleSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.tertiaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: LucideIcons.phone,
                  label: 'Call',
                  filled: true,
                  onTap: onCallDriverPressed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: LucideIcons.message_circle,
                  label: 'Chat',
                  badgeCount: unreadChatMessagesCount,
                  onTap: onChatDriverPressed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: TextButton(
              onPressed: isCancellingTrip ? null : onCancelTripPressed,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.cancel,
                shape: const StadiumBorder(),
              ),
              child: isCancellingTrip
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.cancel,
                      ),
                    )
                  : const Text('Cancel trip'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final int badgeCount;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final background = filled ? AppTheme.primaryColor : AppTheme.neutralColor;
    final foreground = filled ? Colors.white : AppTheme.primaryColor;
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
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
                child: Icon(icon, size: 16, color: foreground),
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
