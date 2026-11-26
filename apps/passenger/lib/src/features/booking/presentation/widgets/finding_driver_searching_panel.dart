import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:foundation/foundation.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/presentation/widgets/finding_driver_route_connector.dart';

class FindingDriverSearchingPanel extends StatelessWidget {
  const FindingDriverSearchingPanel({
    super.key,
    required this.message,
    this.selectedDriverName,
    required this.fare,
    this.baseFare,
    required this.destination,
    this.pickupAddress,
    this.tipAmount,
    this.distance,
    this.duration,
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
  final String? selectedDriverName;
  final double fare;
  final double? baseFare;
  final Place destination;
  final String? pickupAddress;
  final int? tipAmount;
  final String? distance;
  final String? duration;
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
    final trimmedDistance = distance?.trim() ?? '';
    if (trimmedDistance.isNotEmpty) {
      parts.add(trimmedDistance);
    }
    final trimmedDuration = duration?.trim() ?? '';
    if (trimmedDuration.isNotEmpty) {
      parts.add(trimmedDuration);
    }
    if (parts.isEmpty) return 'Drop off';
    return 'Drop off · ${parts.join(' · ')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final pickupTitle = _resolvePickupTitle();
    final pickupSubtitle = _resolvePickupSubtitle();
    final destinationTitle = _resolveDestinationTitle();
    final destinationSubtitle = _resolveDestinationSubtitle();
    final dropoffMeta = _resolveDropoffMeta();

    final resolvedTip = tipAmount ?? 0;
    final explicitBaseFare = baseFare;
    final resolvedBaseFare =
        explicitBaseFare ??
        (fare >= resolvedTip && resolvedTip > 0 ? fare - resolvedTip : fare);
    final resolvedTotalFare = explicitBaseFare != null && tipAmount != null
        ? explicitBaseFare + resolvedTip
        : fare;

    final displayFare = formatPesoAmount(resolvedBaseFare);
    final displayTip = formatPesoAmount(resolvedTip.toDouble());
    final displayTotal = formatPesoAmount(resolvedTotalFare);
    final visibleRefreshError = refreshError?.trim();

    final hairline = colorScheme.outlineVariant.withValues(alpha: 0.7);
    return Material(
      key: const ValueKey<String>('finding-driver-searching-panel'),
      color: colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      shadowColor: colorScheme.onSurface.withValues(alpha: 0.08),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.72,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppLayout.pagePadding,
              AppSpacing.md,
              AppLayout.pagePadding,
              AppLayout.pagePadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: AppSpacing.lg),
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
                          if (selectedDriverName case final driverName?)
                            Text(
                              'Waiting for $driverName',
                              style: context.textStyles.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            )
                          else
                            _SearchingDriverTitle(
                              animate: animate,
                              style: context.textStyles.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            message,
                            style: context.textStyles.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Divider(height: 1, thickness: 1, color: hairline),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  key: const ValueKey<String>('finding-driver-location-card'),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Column(
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: RouteStopMarker(
                                    isPickup: true,
                                    size: 20,
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: SizedBox(
                                      width: 2,
                                      height: double.infinity,
                                      child: FindingDriverRouteConnector(
                                        color: colorScheme.outlineVariant,
                                      ),
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 2),
                                  child: RouteStopMarker(
                                    isPickup: false,
                                    size: 20,
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
                                    style: context.textStyles.labelSmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pickupTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textStyles.bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                  if (pickupSubtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      pickupSubtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.textStyles.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            height: 1.35,
                                          ),
                                    ),
                                  ],
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    child: Divider(height: 1, color: hairline),
                                  ),
                                  Text(
                                    dropoffMeta,
                                    style: context.textStyles.labelSmall
                                        ?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    destinationTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.textStyles.bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                  if (destinationSubtitle.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      destinationSubtitle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.textStyles.bodySmall
                                          ?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            height: 1.35,
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
                        child: Divider(height: 1, color: hairline),
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
                                  style: context.textStyles.bodySmall?.tabular
                                      .copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total: $displayTotal',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textStyles.titleMedium?.tabular
                                      .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onSurface,
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
                if (visibleRefreshError != null &&
                    visibleRefreshError.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          visibleRefreshError,
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                      ),
                      if (onRetryPressed != null)
                        TextButton(
                          onPressed: onRetryPressed,
                          style:
                              TextButton.styleFrom(
                                foregroundColor: colorScheme.onSurface,
                                enableFeedback: false,
                                splashFactory: NoSplash.splashFactory,
                              ).copyWith(
                                overlayColor: WidgetStateProperty.resolveWith(
                                  (states) =>
                                      states.contains(WidgetState.focused)
                                      ? colorScheme.primary.withValues(
                                          alpha: 0.12,
                                        )
                                      : Colors.transparent,
                                ),
                              ),
                          child: const Text('Retry'),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                FilledButton(
                  key: const ValueKey<String>('cancel-booking-button'),
                  onPressed: isCanceling ? null : onCancelPressed,
                  style:
                      FilledButton.styleFrom(
                        backgroundColor: colorScheme.onSurface,
                        foregroundColor: colorScheme.surface,
                        elevation: 0,
                        enableFeedback: false,
                        splashFactory: NoSplash.splashFactory,
                        minimumSize: const Size.fromHeight(
                          AppSize.controlHeight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        textStyle: context.textStyles.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.focused)
                              ? colorScheme.surface.withValues(alpha: 0.16)
                              : Colors.transparent,
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
                      : const Text('Cancel booking'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchingDriverTitle extends StatefulWidget {
  const _SearchingDriverTitle({required this.animate, required this.style});

  final bool animate;
  final TextStyle? style;

  @override
  State<_SearchingDriverTitle> createState() => _SearchingDriverTitleState();
}

class _SearchingDriverTitleState extends State<_SearchingDriverTitle> {
  static const Duration _dotInterval = Duration(milliseconds: 500);

  Timer? _dotTimer;
  int _dotCount = 3;

  void _syncTimer() {
    final shouldRun =
        widget.animate &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (shouldRun) {
      _dotTimer ??= Timer.periodic(_dotInterval, (_) {
        if (!mounted) return;
        setState(() {
          _dotCount = _dotCount <= 1 ? 3 : _dotCount - 1;
        });
      });
    } else {
      _dotTimer?.cancel();
      _dotTimer = null;
      if (_dotCount != 3 && mounted) {
        setState(() => _dotCount = 3);
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _SearchingDriverTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      _syncTimer();
    }
  }

  @override
  void dispose() {
    _dotTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'Searching for a driver',
        children: [
          TextSpan(text: '.' * _dotCount),
          // Keep the title width stable throughout the dots cycle.
          TextSpan(
            text: '.' * (3 - _dotCount),
            style: (widget.style ?? DefaultTextStyle.of(context).style)
                .copyWith(color: Colors.transparent),
          ),
        ],
      ),
      style: widget.style,
      semanticsLabel: 'Searching for a driver',
    );
  }
}
