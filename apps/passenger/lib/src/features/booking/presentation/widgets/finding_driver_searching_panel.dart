import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:maps/maps.dart';

class FindingDriverSearchingPanel extends StatelessWidget {
  const FindingDriverSearchingPanel({
    super.key,
    required this.message,
    required this.fare,
    this.baseFare,
    required this.destination,
    this.pickupAddress,
    this.tipAmount,
    this.distance,
    this.duration,
    this.bookingReference = '',
    this.expiresAt,
    this.requestCreated = false,
    this.isSendingRequest = false,
    this.animate = true,
    this.refreshError,
    this.onRetryPressed,
    required this.onCancelPressed,
    this.isCanceling = false,
  });

  final String message;
  final double fare;
  final double? baseFare;
  final Place destination;
  final String? pickupAddress;
  final int? tipAmount;
  final String? distance;
  final String? duration;
  final String bookingReference;
  final DateTime? expiresAt;
  final bool requestCreated;
  final bool isSendingRequest;
  final bool animate;
  final String? refreshError;
  final VoidCallback? onRetryPressed;
  final VoidCallback onCancelPressed;
  final bool isCanceling;

  String _resolvePickupTitle() {
    final addr = pickupAddress?.trim() ?? '';
    if (addr.isEmpty) return 'Current location';
    final commaIndex = addr.indexOf(',');
    if (commaIndex > 0) {
      return addr.substring(0, commaIndex).trim();
    }
    return addr;
  }

  String _resolvePickupSubtitle() {
    final addr = pickupAddress?.trim() ?? '';
    if (addr.isEmpty) return 'Current pickup location';
    return addr;
  }

  String _resolveDestinationTitle() {
    final name = destination.name.trim();
    if (name.isNotEmpty) return name;
    return destination.displayName;
  }

  String _resolveDestinationSubtitle() {
    final full = destination.fullAddress.trim();
    if (full.isNotEmpty) return full;
    return _resolveDestinationTitle();
  }

  String _resolveDropoffMeta() {
    final parts = <String>[];
    if (distance != null && distance!.trim().isNotEmpty) {
      parts.add(distance!.trim());
    }
    if (duration != null && duration!.trim().isNotEmpty) {
      parts.add(duration!.trim());
    }
    if (parts.isEmpty) return 'Drop off';
    return 'Drop off · ${parts.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final displayBookingId = bookingReference.trim();
    final pickupTitle = _resolvePickupTitle();
    final pickupSubtitle = _resolvePickupSubtitle();
    final destinationTitle = _resolveDestinationTitle();
    final destinationSubtitle = _resolveDestinationSubtitle();
    final dropoffMeta = _resolveDropoffMeta();

    final resolvedTip = tipAmount ?? 0;
    final resolvedBaseFare =
        baseFare ??
        (fare >= resolvedTip && resolvedTip > 0 ? fare - resolvedTip : fare);
    final resolvedTotalFare = baseFare != null && tipAmount != null
        ? baseFare! + resolvedTip
        : fare;

    final displayFare = formatPesoAmount(resolvedBaseFare);
    final displayTip = formatPesoAmount(resolvedTip.toDouble());
    final displayTotal = formatPesoAmount(resolvedTotalFare);

    return Material(
      key: const ValueKey<String>('finding-driver-searching-panel'),
      color: colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 12,
      shadowColor: colorScheme.onSurface.withValues(alpha: 0.12),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Searching for a driver',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayBookingId.isEmpty
                                    ? message
                                    : 'Booking ID: $displayBookingId',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (displayBookingId.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Material(
                                color: colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                                child: Tooltip(
                                  message: 'Copy Booking ID',
                                  child: InkWell(
                                    key: const ValueKey<String>(
                                      'copy-booking-id-button',
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () async {
                                      await Clipboard.setData(
                                        ClipboardData(text: displayBookingId),
                                      );
                                      if (context.mounted) {
                                        CustomToast.show(
                                          context,
                                          'Booking ID copied',
                                        );
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Icon(
                                        LucideIcons.copy,
                                        size: 18,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                thickness: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Container(
                key: const ValueKey<String>('finding-driver-location-card'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  LucideIcons.map_pin,
                                  size: 20,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: CustomPaint(
                                    size: const Size(2, double.infinity),
                                    painter: _DashedLinePainter(
                                      color: colorScheme.outlineVariant,
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Icon(
                                  LucideIcons.navigation,
                                  size: 20,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pick up · Now',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  pickupTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (pickupSubtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    pickupSubtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    thickness: 0.8,
                                    color: colorScheme.outlineVariant
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                                Text(
                                  dropoffMeta,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  destinationTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                if (destinationSubtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    destinationSubtitle,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Divider(
                        height: 1,
                        thickness: 0.8,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$displayFare | Tip: $displayTip',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total: $displayTotal',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (refreshError?.trim().isNotEmpty == true) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        refreshError!,
                        style: TextStyle(
                          color: colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (onRetryPressed != null)
                      TextButton(
                        onPressed: onRetryPressed,
                        child: const Text('Retry'),
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: FilledButton(
                  key: const ValueKey<String>('cancel-booking-button'),
                  onPressed: isCanceling ? null : onCancelPressed,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.onSurface,
                    foregroundColor: colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: isCanceling
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.surface,
                          ),
                        )
                      : const Text(
                          'Cancel booking',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  static const double _dashHeight = 3.5;
  static const double _gapHeight = 3.5;
  static const double _strokeWidth = 1.5;

  final Color color;

  const _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;

    double startY = 4.0;
    while (startY < size.height - 4.0) {
      final endY = (startY + _dashHeight).clamp(0.0, size.height - 4.0);
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, endY),
        paint,
      );
      startY += _dashHeight + _gapHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
