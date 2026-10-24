import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_state.dart';
import 'package:driver/src/presentation/formatters/driver_value_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';

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
  bool _closing = false;
  String? _error;

  Map<String, dynamic>? _request(DashboardState state) {
    if (!state.isOnline || state.hasActiveRide) return null;
    for (final bid in state.activeBids) {
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
    if (_submitting || _request(widget.cubit.state) == null) return;
    final expiry = DateTime.tryParse(valueAsString(bid['expires_at']) ?? '');
    if (expiry != null && !expiry.isAfter(DateTime.now())) {
      widget.cubit.removeExpiredRideOffers();
      return;
    }
    final fare = fareInPesos(bid);
    if (accept && fare == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    bool succeeded;
    if (accept) {
      succeeded = await widget.cubit.submitRideOffer(
        sessionId: widget.sessionId,
        farePesos: fare!,
      );
    } else if (bid['target_driver_id'] != null) {
      succeeded = await widget.cubit.declineRideRequest(widget.sessionId);
    } else {
      widget.cubit.removeActiveBid(widget.sessionId);
      succeeded = true;
    }
    if (!mounted) return;
    if (succeeded) {
      _close();
    } else {
      setState(() {
        _submitting = false;
        _error =
            widget.cubit.state.errorMessage ??
            'Unable to respond. Please try again.';
      });
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<DashboardCubit, DashboardState>(
    bloc: widget.cubit,
    builder: (context, state) {
      final bid = _request(state);
      if (bid == null) _close();
      final colors = context.colorScheme;
      final expiry = DateTime.tryParse(valueAsString(bid?['expires_at']) ?? '');
      final seconds = expiry
          ?.difference(DateTime.now())
          .inSeconds
          .clamp(0, 3599);
      final fare = bid == null ? null : fareInPesos(bid);
      return PopScope(
        canPop: _closing,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Ride request'),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.xxl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              bid?['target_driver_id'] != null
                                  ? 'A passenger chose you'
                                  : 'A passenger needs a ride',
                              style: context.textStyles.headlineSmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              seconds == null
                                  ? 'Review the trip before accepting.'
                                  : 'Respond within $seconds seconds',
                              style: context.textStyles.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxl),
                            Text(
                              fare == null
                                  ? 'Fare unavailable'
                                  : formatPesoAmount(fare),
                              style: context.textStyles.displaySmall,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text('Trip fare'),
                            const SizedBox(height: AppSpacing.xxl),
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
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                'Passenger note',
                                style: context.textStyles.titleSmall,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(note),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_error != null) ...[
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                _error!,
                                style: TextStyle(color: colors.error),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          FilledButton(
                            onPressed:
                                _submitting || bid == null || fare == null
                                ? null
                                : () => unawaited(_respond(bid, accept: true)),
                            child: Text(
                              _submitting ? 'Sending response…' : 'Accept ride',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton(
                            onPressed: _submitting || bid == null
                                ? null
                                : () => unawaited(_respond(bid, accept: false)),
                            child: const Text('Decline'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
