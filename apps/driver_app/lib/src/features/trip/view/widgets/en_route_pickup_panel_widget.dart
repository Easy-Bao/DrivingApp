import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class EnRoutePickupPanelWidget extends StatelessWidget {
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

  const EnRoutePickupPanelWidget({
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
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.14),
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
              color: AppTheme.borderSide,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statusPill(),
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
          const SizedBox(height: 10),
          _routeCard(),
          const SizedBox(height: 10),
          _passengerRow(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionButton(
                  icon: LucideIcons.phone,
                  label: 'Call',
                  filled: true,
                  onPressed: onCallPressed,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionButton(
                  icon: LucideIcons.message_circle,
                  label: 'Chat',
                  badgeCount: unreadChatMessagesCount,
                  onPressed: onChatPressed,
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

  Widget _statusPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.complete.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.navigation, size: 13, color: AppTheme.complete),
          SizedBox(width: 6),
          Text(
            'To pickup',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.complete,
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        children: [
          _routeLine(
            icon: LucideIcons.circle_dot,
            label: 'PICKUP',
            value: pickup,
            accent: AppTheme.primaryColor,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 1,
                height: 10,
                color: AppTheme.borderSide,
              ),
            ),
          ),
          _routeLine(
            icon: LucideIcons.map_pin,
            label: 'DESTINATION',
            value: dropoff,
            accent: AppTheme.tertiaryColor,
          ),
        ],
      ),
    );
  }

  Widget _routeLine({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: accent),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.tertiaryColor.withValues(alpha: 0.8),
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
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

  Widget _passengerRow() {
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
            decoration: BoxDecoration(
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
            child: Text(
              passengerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          Text(
            '${distance.toStringAsFixed(1)} km',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.tertiaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
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
            color: AppTheme.complete.withValues(alpha: 0.12),
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.complete,
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
                    decoration: const BoxDecoration(
                      color: AppTheme.complete,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isConfirmingArrival
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              LucideIcons.chevron_right,
                              color: Colors.white,
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
