import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/core/formatters/value_formatters.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';

class IncomingRideRequestPage extends StatefulWidget {
  const IncomingRideRequestPage({
    super.key,
    required this.cubit,
    required this.sessionId,
  });

  final DashboardCubit cubit;
  final String sessionId;

  @override
  State<IncomingRideRequestPage> createState() =>
      _IncomingRideRequestPageState();
}

class _IncomingRideRequestPageState extends State<IncomingRideRequestPage> {
  Timer? _timer;
  bool _submitting = false;
  bool _accepted = false;
  bool _closing = false;

  Map<String, dynamic>? _request(DashboardState state) {
    if (!state.isOnline || state.isAtBookingCapacity) return null;
    for (final bid in [...state.activeBids, ...state.submittedOffers]) {
      if (valueAsString(bid['id']) == widget.sessionId) return bid;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      widget.cubit.removeExpiredRideOffers();
      if (mounted) setState(() {});
    });
    if (_request(widget.cubit.state) == null) {
      _close();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
    });
  }

  Future<void> _respond(
    Map<String, dynamic> bid, {
    required bool accept,
  }) async {
    if (_submitting || _accepted || _request(widget.cubit.state) == null) {
      return;
    }
    final expiry = DateTime.tryParse(valueAsString(bid['expires_at']) ?? '');
    if (expiry != null && !expiry.isAfter(DateTime.now())) {
      widget.cubit.removeExpiredRideOffers();
      return;
    }
    final fare = fareInPesos(bid);
    if (accept && fare == null) return;
    setState(() {
      _submitting = true;
    });
    bool succeeded;
    if (accept && fare != null) {
      succeeded = await widget.cubit.submitRideOffer(
        sessionId: widget.sessionId,
        farePesos: fare,
      );
    } else if (bid['target_driver_id'] != null) {
      succeeded = await widget.cubit.declineRideRequest(widget.sessionId);
    } else {
      widget.cubit.removeActiveBid(widget.sessionId);
      succeeded = true;
    }
    if (!mounted) return;
    if (succeeded && accept) {
      setState(() {
        _accepted = true;
        _submitting = false;
      });
    } else if (succeeded) {
      _close();
    } else {
      if (mounted) {
        final message =
            widget.cubit.state.errorMessage ??
            'Unable to respond. Please try again.';
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
            ),
          );
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<DashboardCubit, DashboardState>(
    bloc: widget.cubit,
    listenWhen: (_, state) => _request(state) == null,
    listener: (_, _) => _close(),
    builder: (context, state) {
      final bid = _request(state);
      final colorScheme = context.colorScheme;
      final textStyles = context.textStyles;
      final expiry = DateTime.tryParse(valueAsString(bid?['expires_at']) ?? '');
      final seconds = expiry
          ?.difference(DateTime.now())
          .inSeconds
          .clamp(0, 3599);
      final fare = bid == null ? null : fareInPesos(bid);
      final isDirect = bid?['target_driver_id'] != null;
      final awaitingAssignment =
          _accepted ||
          state.submittedOffers.any(
            (offer) => valueAsString(offer['id']) == widget.sessionId,
          );
      final hairline = Divider(
        height: 1,
        thickness: 1,
        color: colorScheme.outlineVariant.withValues(alpha: 0.7),
      );

      return PopScope(
        canPop: _closing,
        child: Scaffold(
          backgroundColor: context.canvasColor,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.pageMaxWidth,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding = constraints.maxWidth < 360
                        ? AppLayout.pagePadding
                        : AppLayout.pagePaddingWide;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            AppSpacing.lg,
                            horizontalPadding,
                            AppSpacing.md,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    'RIDE REQUEST',
                                    style: textStyles.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                              if (seconds != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                    border: Border.all(
                                      color: seconds <= 10
                                          ? colorScheme.error.withValues(
                                              alpha: 0.45,
                                            )
                                          : colorScheme.outlineVariant,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ExcludeSemantics(
                                        child: Icon(
                                          LucideIcons.clock,
                                          size: 13,
                                          color: seconds <= 10
                                              ? colorScheme.error
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${seconds}s',
                                        style: textStyles.labelSmall?.tabular
                                            .copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: seconds <= 10
                                                  ? colorScheme.error
                                                  : colorScheme.onSurface,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        hairline,
                        Expanded(
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              AppSpacing.xxl,
                              horizontalPadding,
                              AppSpacing.xxl,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  isDirect
                                      ? 'A passenger chose you'
                                      : 'A passenger needs a ride',
                                  style: textStyles.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.3,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs + 2),
                                Text(
                                  seconds == null
                                      ? 'Review the trip before accepting.'
                                      : 'Respond within $seconds seconds',
                                  style: textStyles.bodyMedium?.tabular
                                      .copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                Text(
                                  'Trip fare',
                                  style: textStyles.labelMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    fare == null
                                        ? 'Fare unavailable'
                                        : formatPesoAmount(fare),
                                    style: textStyles.displayLarge?.tabular
                                        .copyWith(
                                          fontSize: 40,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -1.4,
                                          color: colorScheme.onSurface,
                                        ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xxl),
                                hairline,
                                const SizedBox(height: AppSpacing.xl),
                                Semantics(
                                  header: true,
                                  child: Text(
                                    'ROUTE',
                                    style: textStyles.labelSmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                CompactRouteTimeline(
                                  pickup:
                                      valueAsString(bid?['pickup_name']) ??
                                      'Pickup unavailable',
                                  dropoff:
                                      valueAsString(bid?['dropoff_name']) ??
                                      'Destination unavailable',
                                ),
                                if (valueAsString(bid?['passenger_note'])
                                    case final String note) ...[
                                  const SizedBox(height: AppSpacing.xl),
                                  hairline,
                                  const SizedBox(height: AppSpacing.xl),
                                  Text(
                                    'Passenger note',
                                    style: textStyles.labelMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.only(
                                      left: AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: colorScheme.outlineVariant,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      note,
                                      style: textStyles.bodyMedium?.copyWith(
                                        color: colorScheme.onSurface,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.canvasColor,
                            border: Border(
                              top: BorderSide(
                                color: colorScheme.outlineVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              horizontalPadding,
                              AppSpacing.lg,
                              horizontalPadding,
                              AppSpacing.lg,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (awaitingAssignment) ...[
                                  const LinearProgressIndicator(minHeight: 3),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Confirming your trip…',
                                    textAlign: TextAlign.center,
                                    style: textStyles.titleSmall?.copyWith(
                                      color: colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ] else ...[
                                  SizedBox(
                                    height: AppSize.controlHeight,
                                    child: FilledButton(
                                      key: const ValueKey<String>(
                                        'driver-request-accept',
                                      ),
                                      onPressed:
                                          _submitting ||
                                              bid == null ||
                                              fare == null
                                          ? null
                                          : () => unawaited(
                                              _respond(bid, accept: true),
                                            ),
                                      style:
                                          FilledButton.styleFrom(
                                            backgroundColor:
                                                colorScheme.primary,
                                            foregroundColor:
                                                colorScheme.onPrimary,
                                            elevation: 0,
                                            enableFeedback: false,
                                            splashFactory:
                                                NoSplash.splashFactory,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.lg,
                                                  ),
                                            ),
                                          ).copyWith(
                                            overlayColor:
                                                WidgetStateProperty.resolveWith(
                                                  (states) {
                                                    if (states.contains(
                                                      WidgetState.focused,
                                                    )) {
                                                      return colorScheme
                                                          .onPrimary
                                                          .withValues(
                                                            alpha: 0.16,
                                                          );
                                                    }
                                                    return Colors.transparent;
                                                  },
                                                ),
                                          ),
                                      child: Text(
                                        _submitting
                                            ? 'Sending response…'
                                            : 'Accept ride',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm + 2),
                                  SizedBox(
                                    height: AppSize.controlHeight,
                                    child: OutlinedButton(
                                      key: const ValueKey<String>(
                                        'driver-request-decline',
                                      ),
                                      onPressed: _submitting || bid == null
                                          ? null
                                          : () => unawaited(
                                              _respond(bid, accept: false),
                                            ),
                                      style:
                                          OutlinedButton.styleFrom(
                                            foregroundColor:
                                                colorScheme.onSurface,
                                            backgroundColor: Colors.transparent,
                                            side: BorderSide(
                                              color: colorScheme.outlineVariant,
                                            ),
                                            enableFeedback: false,
                                            splashFactory:
                                                NoSplash.splashFactory,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppRadius.lg,
                                                  ),
                                            ),
                                          ).copyWith(
                                            overlayColor:
                                                WidgetStateProperty.resolveWith(
                                                  (states) {
                                                    if (states.contains(
                                                      WidgetState.focused,
                                                    )) {
                                                      return colorScheme.primary
                                                          .withValues(
                                                            alpha: 0.12,
                                                          );
                                                    }
                                                    return Colors.transparent;
                                                  },
                                                ),
                                          ),
                                      child: const Text('Decline'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
