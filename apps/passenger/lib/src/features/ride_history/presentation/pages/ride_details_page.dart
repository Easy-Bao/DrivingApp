import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/active_ride_routes.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/chat/chat_routes.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_details/ride_details_cubit.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_details_map.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:url_launcher/url_launcher.dart';

class RideDetailsPage extends StatefulWidget {
  const RideDetailsPage({
    super.key,
    required this.trackRepository,
    required this.sessionService,
    required this.profileRepository,
    this.detailsCubit,
    this.ride,
    this.rideId,
    this.initialRide,
    this.showRatingAction = true,
  });
  final bool showRatingAction;
  final RideHistory? ride;
  final String? rideId;
  final RideSnapshot? initialRide;
  final TrackRepository trackRepository;
  final SessionStore sessionService;
  final DriverProfileRepository profileRepository;
  final RideDetailsCubit? detailsCubit;

  @override
  State<RideDetailsPage> createState() => _RideDetailsPageState();
}

class _RideDetailsPageState extends State<RideDetailsPage> {
  late final RideDetailsCubit _detailsCubit;
  StreamSubscription<RideDetailsState>? _detailsSubscription;
  RideSnapshot? _detailedRideData;
  RideCounterparty? _counterpartyData;
  bool _showLostFoundChat = false;
  String _passengerId = '';
  String? _contactError;

  String? get _rideId =>
      widget.ride?.id ?? widget.initialRide?.id ?? widget.rideId;

  RideSnapshot? get _snapshot => _detailedRideData ?? widget.initialRide;

  @override
  void initState() {
    super.initState();
    _detailsCubit =
        widget.detailsCubit ??
        RideDetailsCubit(
          repository: widget.trackRepository,
          sessionService: widget.sessionService,
          profileRepository: widget.profileRepository,
        );
    _syncDetailsState(_detailsCubit.state);
    _detailsSubscription = _detailsCubit.stream.listen((state) {
      if (!mounted) return;
      setState(() => _syncDetailsState(state));
      _loadReviewIfEligible(state);
    });
    final rideId = _rideId;
    if (rideId != null) {
      unawaited(_detailsCubit.load(rideId));
      _loadReviewIfEligible(_detailsCubit.state);
    }
  }

  void _loadReviewIfEligible(RideDetailsState state) {
    final ride = state.ride ?? widget.initialRide;
    final status = ride?.status ?? widget.ride?.status;
    final driverId = ride?.driverId ?? widget.ride?.driverId;
    final rideId = state.rideId.isNotEmpty ? state.rideId : _rideId;
    if (rideId == null ||
        status?.toLowerCase() != 'completed' ||
        driverId?.trim().isNotEmpty != true) {
      return;
    }
    unawaited(_detailsCubit.loadMyReview(rideId));
  }

  void _syncDetailsState(RideDetailsState state) {
    _passengerId = state.passengerId;
    _detailedRideData = state.ride;
    _counterpartyData = state.counterparty;
    _showLostFoundChat = state.canContactCounterparty;
  }

  @override
  void dispose() {
    unawaited(_detailsSubscription?.cancel());
    unawaited(_detailsCubit.close());
    super.dispose();
  }

  Future<void> _initiateLostFoundChat() async {
    final rideId = _rideId;
    final retrievedRideData = _detailedRideData;
    if (rideId == null || retrievedRideData == null || _passengerId.isEmpty) {
      return;
    }

    final driverId =
        _counterpartyData?.userId ?? retrievedRideData.driverId ?? '';
    if (driverId.isEmpty) return;

    try {
      if (mounted) {
        unawaited(
          context.pushNamed(
            ChatRoutes.driverChat,
            extra: {
              'roomId': rideId,
              'userId': _passengerId,
              'peerId': driverId,
              'peerName': SafeParse.toStringValue(
                _counterpartyData?.name ?? retrievedRideData.driverName,
                'Driver',
              ),
            },
          ),
        );
      }
    } catch (_) {}
  }

  Widget _buildReceiptSummary(
    BuildContext context,
    RideSnapshot? snapshot,
    double? fare,
  ) {
    final colors = context.colorScheme;
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Total fare')),
              Text(
                fare == null ? 'Fare unavailable' : formatPesoAmount(fare),
                key: const ValueKey('receipt-total-fare'),
                style: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cash · ${_cashPaymentStatus(snapshot)}',
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          if (snapshot?.cashSettled == true &&
              (snapshot?.cashReceivedAmount ?? 0) > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cash received ${formatPesoAmount(snapshot!.cashReceivedAmount! / 100)}'
              '${(snapshot.cashChangeAmount ?? 0) > 0 ? ' · Change ${formatPesoAmount(snapshot.cashChangeAmount! / 100)}' : ''}',
              style: context.textStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _callDriver() async {
    final counterparty = _counterpartyData;
    if (!_showLostFoundChat ||
        counterparty == null ||
        !counterparty.contactAllowed ||
        counterparty.phone.trim().isEmpty) {
      return;
    }
    try {
      final opened = await launchUrl(
        Uri(scheme: 'tel', path: counterparty.phone.trim()),
      );
      if (!opened && mounted) {
        setState(
          () => _contactError =
              'Unable to open the phone app. Try messaging your driver.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _contactError =
              'Unable to open the phone app. Try messaging your driver.',
        );
      }
    }
  }

  String? _receiptDate(
    BuildContext context,
    RideSnapshot? snapshot,
    RideHistory? ride,
  ) {
    final date = snapshot?.completedAt ?? DateTime.tryParse(ride?.date ?? '');
    if (date == null) {
      return ride?.date.trim().isNotEmpty == true ? ride!.date : null;
    }
    final local = date.toLocal();
    final labels = MaterialLocalizations.of(context);
    return '${labels.formatMediumDate(local)} · ${labels.formatTimeOfDay(TimeOfDay.fromDateTime(local))}';
  }

  String _driverInitials(String? name) {
    if (name == null || name.trim().isEmpty) return 'D';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final snapshot = _snapshot;
    final rideId = _rideId;
    final fare =
        snapshot?.farePesos ??
        (ride == null
            ? null
            : double.tryParse(ride.price.replaceAll(RegExp(r'[^0-9.\-]'), '')));
    final status = (snapshot?.status ?? ride?.status ?? 'unknown')
        .toLowerCase();
    final isCompleted = status == 'completed';
    final pickupLatitude = ride?.pickupLat ?? snapshot?.pickupLatitude;
    final pickupLongitude = ride?.pickupLng ?? snapshot?.pickupLongitude;
    final dropoffLatitude = ride?.destLat ?? snapshot?.dropoffLatitude;
    final dropoffLongitude = ride?.destLng ?? snapshot?.dropoffLongitude;
    final reference =
        snapshot?.bookingReference ?? ride?.bookingReference ?? '';
    final driverName =
        _counterpartyData?.name ??
        ride?.displayDriverName ??
        snapshot?.displayDriverName ??
        'Driver';

    return TripReceiptLayout(
      dateLabel: _receiptDate(context, snapshot, ride),
      onBack: () => context.pop(),
      child: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_detailsCubit.state.errorMessage != null && rideId != null) ...[
              AppErrorBanner(
                message: _detailsCubit.state.errorMessage!,
                onRetry: () => unawaited(_detailsCubit.load(rideId)),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (reference.trim().isNotEmpty) ...[
              TripReference(id: reference, expanded: true, compact: true),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text('Driver', style: context.textStyles.labelSmall),
            const SizedBox(height: AppSpacing.sm),
            AppSurfaceCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        context.colorScheme.surfaceContainerHighest,
                    foregroundColor: context.colorScheme.onSurface,
                    child: Text(_driverInitials(driverName)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driverName, style: context.textStyles.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          ride?.displayVehicleSummary ??
                              snapshot?.displayVehicleSummary ??
                              'Vehicle details unavailable',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showLostFoundChat)
                    IconButton.outlined(
                      tooltip: 'Message driver',
                      onPressed: _initiateLostFoundChat,
                      icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    ),
                  if (_showLostFoundChat &&
                      _counterpartyData?.phone.trim().isNotEmpty == true)
                    IconButton.outlined(
                      tooltip: 'Call driver',
                      onPressed: _callDriver,
                      icon: const Icon(Icons.phone_outlined, size: 20),
                    ),
                ],
              ),
            ),
            if (_contactError != null)
              Text(
                _contactError!,
                style: TextStyle(color: context.colorScheme.error),
              ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: Text('Route', style: context.textStyles.labelSmall),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (isCompleted
                                ? context.semanticColors.success
                                : context.colorScheme.onSurfaceVariant)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    switch (status) {
                      'completed' => 'Completed',
                      'cancelled' || 'canceled' => 'Canceled',
                      'assigned' || 'accepted' => 'Awaiting pickup',
                      'arrived' => 'At pickup',
                      'in_transit' => 'In progress',
                      'requested' => 'Requested',
                      _ => 'Unknown',
                    },
                    style: context.textStyles.labelSmall?.copyWith(
                      color: isCompleted
                          ? context.semanticColors.success
                          : context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  if (pickupLatitude != null &&
                      pickupLongitude != null &&
                      dropoffLatitude != null &&
                      dropoffLongitude != null)
                    SizedBox(
                      height: 180,
                      child: RideDetailsMap(
                        key: ValueKey((
                          pickupLatitude,
                          pickupLongitude,
                          dropoffLatitude,
                          dropoffLongitude,
                        )),
                        pickupLatitude: pickupLatitude,
                        pickupLongitude: pickupLongitude,
                        dropoffLatitude: dropoffLatitude,
                        dropoffLongitude: dropoffLongitude,
                      ),
                    ),
                  if (snapshot?.distanceKm != null ||
                      snapshot?.durationMinutes != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        0,
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          [
                            if (snapshot?.distanceKm case final distance?)
                              distance < 1
                                  ? '${(distance * 1000).round()} m'
                                  : '${distance.toStringAsFixed(1)} km',
                            if (snapshot?.durationMinutes case final duration?)
                              '${duration.round()} min',
                          ].join(' · '),
                          style: context.textStyles.labelSmall,
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: CompactRouteTimeline(
                      pickup:
                          ride?.pickup ??
                          snapshot?.pickupName ??
                          'Pickup location',
                      dropoff:
                          ride?.destination ??
                          snapshot?.dropoffName ??
                          'Destination location',
                    ),
                  ),
                ],
              ),
            ),
            if (isCompleted &&
                snapshot?.driverId?.isNotEmpty == true &&
                rideId != null) ...[
              const SizedBox(height: AppSpacing.md),
              if (_detailsCubit.state.submittedReview case final review?)
                AppSurfaceCard(
                  child: Row(
                    children: [
                      const Expanded(child: Text('Ride rating')),
                      Text(review.rating.toStringAsFixed(0)),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: context.semanticColors.rating,
                      ),
                    ],
                  ),
                )
              else if (widget.showRatingAction &&
                  !_detailsCubit.state.isLoadingReview)
                TextButton(
                  onPressed: () async {
                    await context.pushNamed(
                      ActiveRideRoutes.tripCompletion,
                      extra: (ride: snapshot!, returnToReceipt: true),
                    );
                    if (mounted) {
                      await _detailsCubit.loadMyReview(rideId, refresh: true);
                    }
                  },
                  child: const Text('Rate this ride'),
                ),
            ],
            if (isCompleted) ...[
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Fare breakdown',
                style: context.textStyles.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildReceiptSummary(context, snapshot, fare),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: rideId == null || rideId.isEmpty
                  ? null
                  : () => showSafetyReportSheet(
                      context,
                      rideId: rideId,
                      driverName: driverName,
                      vehiclePlate:
                          ride?.vehiclePlate ?? snapshot?.plateNumber ?? '',
                      vehicleType:
                          ride?.vehicleType ?? snapshot?.vehicleType ?? '',
                      trackRepository: widget.trackRepository,
                    ),
              child: const Text('Report an issue'),
            ),
          ],
        ),
      ),
    );
  }
}

String _cashPaymentStatus(RideSnapshot? ride) {
  if (ride == null) return 'Status unavailable.';
  if (!ride.cashSettled) return 'Awaiting driver confirmation.';
  return switch (ride.cashOutcome) {
    'paid' => 'Driver confirmed cash received.',
    'partial' => 'Driver recorded partial payment.',
    'refused' => 'Driver recorded that cash was refused.',
    'unpaid' => 'Driver recorded no cash received.',
    'disputed' => 'Outcome disputed. Report an issue if needed.',
    _ => 'Payment status unavailable.',
  };
}
