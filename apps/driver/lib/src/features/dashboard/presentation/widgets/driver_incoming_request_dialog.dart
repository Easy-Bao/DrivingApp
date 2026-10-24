import 'package:design_system/design_system.dart';
import 'package:driver/src/presentation/formatters/driver_value_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';

double? _extractDistanceInKm(Map<String, dynamic> value) {
  final distance = value['distance_km'] ?? value['distance'];
  return distance is num && distance >= 0 ? distance.toDouble() : null;
}

class IncomingRequestDialog extends StatefulWidget {
  const IncomingRequestDialog({
    super.key,
    required this.bid,
    required this.submittingBidId,
    required this.onDecline,
    required this.onSubmitOffer,
    this.onTimeout,
    this.totalDuration = const Duration(seconds: 30),
    this.controller,
  });

  final Map<String, dynamic> bid;
  final String? submittingBidId;
  final VoidCallback onDecline;
  final VoidCallback onSubmitOffer;
  final VoidCallback? onTimeout;
  final Duration totalDuration;
  final AnimationController? controller;

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> bid,
    String? submittingBidId,
    required VoidCallback onDecline,
    required VoidCallback onSubmitOffer,
    VoidCallback? onTimeout,
    Duration totalDuration = const Duration(seconds: 30),
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: context.colorScheme.scrim,
      builder: (context) => _IncomingRequestDialogRoute(
        bid: bid,
        submittingBidId: submittingBidId,
        onDecline: onDecline,
        onSubmitOffer: onSubmitOffer,
        onTimeout: onTimeout,
        totalDuration: totalDuration,
      ),
    );
  }

  @override
  State<IncomingRequestDialog> createState() => _IncomingRequestDialogState();
}

class _IncomingRequestDialogRoute extends StatefulWidget {
  const _IncomingRequestDialogRoute({
    required this.bid,
    required this.submittingBidId,
    required this.onDecline,
    required this.onSubmitOffer,
    required this.onTimeout,
    required this.totalDuration,
  });

  final Map<String, dynamic> bid;
  final String? submittingBidId;
  final VoidCallback onDecline;
  final VoidCallback onSubmitOffer;
  final VoidCallback? onTimeout;
  final Duration totalDuration;

  @override
  State<_IncomingRequestDialogRoute> createState() =>
      _IncomingRequestDialogRouteState();
}

class _IncomingRequestDialogRouteState
    extends State<_IncomingRequestDialogRoute> {
  bool _isClosing = false;

  void _close(VoidCallback? action) {
    if (_isClosing) return;
    setState(() => _isClosing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      action?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _isClosing,
      child: IncomingRequestDialog(
        bid: widget.bid,
        submittingBidId: widget.submittingBidId,
        onDecline: () => _close(widget.onDecline),
        onSubmitOffer: () => _close(widget.onSubmitOffer),
        onTimeout: () => _close(widget.onTimeout),
        totalDuration: widget.totalDuration,
      ),
    );
  }
}

class _IncomingRequestDialogState extends State<IncomingRequestDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final bool _isInternalController;
  bool _isSubmittingOffer = false;

  @override
  void initState() {
    super.initState();
    _isInternalController = widget.controller == null;
    final remainingDuration = _calculateRemainingDuration();
    final effectiveController =
        widget.controller ??
        AnimationController(vsync: this, duration: widget.totalDuration);
    _controller = effectiveController;

    if (_isInternalController) {
      final initialFraction = widget.totalDuration.inMilliseconds > 0
          ? (remainingDuration.inMilliseconds /
                    widget.totalDuration.inMilliseconds)
                .clamp(0.0, 1.0)
          : 0.0;
      _controller.value = initialFraction;
      if (initialFraction > 0.0) {
        _controller.reverse(from: initialFraction);
      }
    }

    _controller.addStatusListener(_onAnimationStatusChanged);
  }

  Duration _calculateRemainingDuration() {
    final rawExpiry = valueAsString(widget.bid['expires_at']);
    final expiresAt = rawExpiry == null ? null : DateTime.tryParse(rawExpiry);
    if (expiresAt == null) return widget.totalDuration;
    final diff = expiresAt.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if ((status == AnimationStatus.dismissed ||
            (status == AnimationStatus.completed &&
                _controller.value == 0.0)) &&
        mounted) {
      widget.onTimeout?.call();
    }
  }

  @override
  void didUpdateWidget(covariant IncomingRequestDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.submittingBidId != widget.submittingBidId &&
        widget.submittingBidId == null) {
      _isSubmittingOffer = false;
    }
  }

  void _handleSubmit() {
    if (_isSubmittingOffer || widget.submittingBidId != null) return;
    setState(() => _isSubmittingOffer = true);
    widget.onSubmitOffer();
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatusChanged);
    if (_isInternalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewport = MediaQuery.sizeOf(context);
    final isLandscape = viewport.width > viewport.height;
    final maxDialogHeight = isLandscape
        ? viewport.height * 0.7
        : viewport.height - 48;
    final pickup = widget.bid['pickup_name']?.toString() ?? '—';
    final dropoff = widget.bid['dropoff_name']?.toString() ?? '—';
    final fare = fareInPesos(widget.bid);
    final distance = _extractDistanceInKm(widget.bid);
    final bidId = valueAsString(widget.bid['id']);
    final isSubmitting =
        _isSubmittingOffer ||
        (bidId != null && widget.submittingBidId == bidId);
    final passengerNote = valueAsString(widget.bid['passenger_note']);

    return Dialog(
      backgroundColor: Colors.transparent,
      alignment: Alignment.bottomCenter,
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Container(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: maxDialogHeight),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: context.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.shadow.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: SingleChildScrollView(
            key: const ValueKey('incoming-request-scroll-view'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => LinearProgressIndicator(
                    key: const ValueKey('incoming-request-linear-progress'),
                    value: _controller.value,
                    minHeight: 4,
                    backgroundColor: context.colorScheme.outlineVariant
                        .withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _controller.value < 0.25
                          ? context.colorScheme.error
                          : context.colorScheme.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ride request',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: context.colorScheme.onSurface,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Submit an offer before this session expires',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, _) {
                              final remainingSeconds =
                                  (_controller.value *
                                          widget.totalDuration.inSeconds)
                                      .ceil();
                              final isUrgent = _controller.value < 0.25;
                              return SizedBox(
                                width: 52,
                                height: 52,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      key: const ValueKey(
                                        'incoming-request-countdown-progress',
                                      ),
                                      value: _controller.value,
                                      strokeWidth: 4,
                                      backgroundColor: context
                                          .colorScheme
                                          .outlineVariant
                                          .withValues(alpha: 0.25),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isUrgent
                                            ? context.colorScheme.error
                                            : context.colorScheme.primary,
                                      ),
                                    ),
                                    Text(
                                      '${remainingSeconds}s',
                                      key: const ValueKey(
                                        'incoming-request-countdown-text',
                                      ),
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isUrgent
                                            ? context.colorScheme.error
                                            : context.colorScheme.onSurface,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (valueAsString(widget.bid['booking_reference'])
                          case final String reference
                          when reference.isNotEmpty) ...[
                        TripReference(id: reference, compact: true),
                        const SizedBox(height: 12),
                      ],
                      CompactRouteTimeline(pickup: pickup, dropoff: dropoff),
                      if (passengerNote != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: context.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                LucideIcons.message_square_text,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  passengerNote,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      Text(
                        'The passenger confirms the driver before pickup.',
                        style: context.textStyles.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: context.colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              distance == null
                                  ? 'Distance unavailable'
                                  : '${DistanceFormatter.fromKilometers(distance)} away',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            fare == null ? '—' : formatPesoAmount(fare),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: context.colorScheme.onSurface,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              key: const ValueKey(
                                'incoming-request-decline-button',
                              ),
                              onPressed:
                                  widget.submittingBidId != null ||
                                      _isSubmittingOffer
                                  ? null
                                  : widget.onDecline,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(
                                  0,
                                  AppSize.minimumTouchTarget,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                side: BorderSide(
                                  color: context.colorScheme.outlineVariant,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                              ),
                              child: Text(
                                'Decline',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: context.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              key: const ValueKey(
                                'incoming-request-submit-button',
                              ),
                              onPressed:
                                  fare == null ||
                                      widget.submittingBidId != null ||
                                      _isSubmittingOffer
                                  ? null
                                  : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colorScheme.primary,
                                foregroundColor: context.colorScheme.onPrimary,
                                elevation: 0,
                                minimumSize: const Size(
                                  0,
                                  AppSize.minimumTouchTarget,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
                                ),
                              ),
                              child: isSubmitting
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: context.colorScheme.onPrimary,
                                      ),
                                    )
                                  : Text(
                                      'Accept fare',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: context.colorScheme.onPrimary,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
