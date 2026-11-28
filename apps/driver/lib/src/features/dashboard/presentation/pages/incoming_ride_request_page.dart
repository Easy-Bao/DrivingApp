import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/core/formatters/value_formatters.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/incoming_request_action_bar.dart';
import 'package:driver/src/features/dashboard/presentation/widgets/incoming_request_countdown_badge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  final ValueNotifier<DateTime> _clock = ValueNotifier<DateTime>(
    DateTime.now(),
  );
  Timer? _timer;
  bool _submittingAccept = false;
  bool _submittingDecline = false;
  bool _accepted = false;
  bool _closing = false;

  bool get _isSubmitting => _submittingAccept || _submittingDecline;

  bool _isSubmittedInState(DashboardState state) => state.submittedOffers.any(
    (offer) => valueAsString(offer['id']) == widget.sessionId,
  );

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
    _accepted = _isSubmittedInState(widget.cubit.state);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      widget.cubit.removeExpiredRideOffers();
      if (mounted) _clock.value = DateTime.now();
    });
    if (_request(widget.cubit.state) == null) {
      _close();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock.dispose();
    super.dispose();
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    final wasAccepted = _accepted;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop<bool>(wasAccepted);
      });
    });
  }

  Future<void> _respond(
    Map<String, dynamic> bid, {
    required bool accept,
  }) async {
    if (_isSubmitting || _accepted || _request(widget.cubit.state) == null) {
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
      _submittingAccept = accept;
      _submittingDecline = !accept;
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
      unawaited(HapticFeedback.lightImpact());
      setState(() {
        _accepted = true;
        _submittingAccept = false;
        _submittingDecline = false;
      });
    } else if (succeeded) {
      _close();
    } else {
      if (mounted) {
        final message =
            widget.cubit.state.errorMessage ??
            'Unable to respond. Please try again.';
        widget.cubit.dismissError();
        AppSnackBar.show(context, message, tone: AppSnackBarTone.error);
        setState(() {
          _submittingAccept = false;
          _submittingDecline = false;
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
      final fare = bid == null ? null : fareInPesos(bid);
      final isDirect = bid?['target_driver_id'] != null;
      final awaitingAssignment = _accepted || _isSubmittedInState(state);
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
                              IncomingRequestCountdownBadge(
                                clock: _clock,
                                expiry: expiry,
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
                                if (awaitingAssignment)
                                  Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      'Response sent · Waiting for confirmation',
                                      style: textStyles.bodyMedium?.copyWith(
                                        color: context.semanticColors.success,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  )
                                else
                                  IncomingRequestCountdownLabel(
                                    clock: _clock,
                                    expiry: expiry,
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
                        IncomingRequestActionBar(
                          horizontalPadding: horizontalPadding,
                          awaitingAssignment: awaitingAssignment,
                          submittingAccept: _submittingAccept,
                          submittingDecline: _submittingDecline,
                          canAccept:
                              !_isSubmitting && bid != null && fare != null,
                          canDecline: !_isSubmitting && bid != null,
                          onAccept: () {
                            if (bid != null) {
                              unawaited(_respond(bid, accept: true));
                            }
                          },
                          onDecline: () {
                            if (bid != null) {
                              unawaited(_respond(bid, accept: false));
                            }
                          },
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
