import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/chat/chat_routes.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_details/ride_details_cubit.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_details_map.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_rating_prompt.dart';
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
  });
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
  bool _canContactCounterparty = false;
  String _passengerId = '';

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
    _canContactCounterparty = state.canContactCounterparty;
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

  Future<void> _makeDriverCall() async {
    final rideId = _rideId;
    if (rideId == null) return;
    try {
      RideCounterparty? driverProfile = _counterpartyData;
      driverProfile ??= await _detailsCubit.loadCounterpartyIfNeeded(rideId);
      if (driverProfile == null ||
          !driverProfile.contactAllowed ||
          driverProfile.phone.trim().isEmpty) {
        return;
      }
      final phone = driverProfile.phone.trim();
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {}
  }

  Widget _buildReceiptSummary(
    BuildContext context,
    RideSnapshot? snapshot,
    double? fare,
  ) {
    final colors = context.colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total fare', style: context.textStyles.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            fare == null ? 'Fare unavailable' : formatPesoAmount(fare),
            key: const ValueKey('receipt-total-fare'),
            style: context.textStyles.headlineMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.payments_outlined,
                size: 20,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Cash · ${_cashPaymentStatus(snapshot)}',
                  style: context.textStyles.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (snapshot?.cashSettled == true &&
              (snapshot?.cashReceivedAmount ?? 0) > 0) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Cash received ${formatPesoAmount(snapshot!.cashReceivedAmount! / 100)}'
              '${(snapshot.cashChangeAmount ?? 0) > 0 ? ' · Change ${formatPesoAmount(snapshot.cashChangeAmount! / 100)}' : ''}',
              style: context.textStyles.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
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

    final pickupLatitude = ride?.pickupLat ?? snapshot?.pickupLatitude;
    final pickupLongitude = ride?.pickupLng ?? snapshot?.pickupLongitude;
    final dropoffLatitude = ride?.destLat ?? snapshot?.dropoffLatitude;
    final dropoffLongitude = ride?.destLng ?? snapshot?.dropoffLongitude;
    final status = (snapshot?.status ?? ride?.status ?? 'unknown')
        .toLowerCase();
    final isCompleted = status == 'completed';
    final Color statusColor;
    final String statusLabel;
    final String statusSubtitle;

    if (status == 'completed') {
      statusColor = context.semanticColors.success;
      statusLabel = 'Completed';
      statusSubtitle = 'Trip finished';
    } else if (status == 'canceled' || status == 'cancelled') {
      statusColor = context.colorScheme.error;
      statusLabel = 'Canceled';
      statusSubtitle = 'Trip canceled';
    } else {
      statusColor = context.semanticColors.success;
      statusLabel = 'In Progress';
      statusSubtitle = 'Trip is in progress';
    }

    return AppSecondaryPage(
      title: isCompleted ? 'Trip receipt' : 'Ride details',
      subtitle:
          (snapshot?.bookingReference ?? ride?.bookingReference ?? '')
              .trim()
              .isEmpty
          ? null
          : 'Booking ID - ${snapshot?.bookingReference ?? ride?.bookingReference}',
      onBack: () => context.pop(),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          children: [
            if (isCompleted) ...[
              _buildReceiptSummary(context, snapshot, fare),
              if (snapshot?.driverId?.trim().isNotEmpty == true &&
                  rideId?.isNotEmpty == true) ...[
                const SizedBox(height: 12),
                RideRatingPrompt(
                  driverId: snapshot!.driverId!,
                  driverName: snapshot.displayDriverName,
                  rideId: rideId!,
                  cubit: _detailsCubit,
                  onDone: () => context.goNamed(HomeRoutes.home),
                  initiallyExpanded:
                      widget.initialRide != null ||
                      (widget.ride == null && widget.rideId != null),
                ),
              ],
              const SizedBox(height: 12),
            ],
            if (pickupLatitude != null &&
                pickupLongitude != null &&
                dropoffLatitude != null &&
                dropoffLongitude != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: context.colorScheme.outlineVariant,
                    width: 1.0,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x06000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg - 1),
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
              ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: context.colorScheme.outlineVariant,
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _driverInitials(
                        ride?.displayDriverName ?? snapshot?.displayDriverName,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride?.displayDriverName ??
                              snapshot?.displayDriverName ??
                              'Driver',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: context.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ride?.displayVehicleSummary ??
                              snapshot?.displayVehicleSummary ??
                              'Vehicle details unavailable',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_canContactCounterparty) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: context.colorScheme.surface,
                      shape: CircleBorder(
                        side: BorderSide(
                          color: context.colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                          width: 1.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Semantics(
                        button: true,
                        label: 'Call driver',
                        child: InkWell(
                          onTap: _makeDriverCall,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              LucideIcons.phone,
                              color: context.colorScheme.onSurface,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (status != 'completed' || _showLostFoundChat) ...[
                    const SizedBox(width: 8),
                    Material(
                      color: context.colorScheme.surface,
                      shape: CircleBorder(
                        side: BorderSide(
                          color: context.colorScheme.outlineVariant.withValues(
                            alpha: 0.4,
                          ),
                          width: 1.0,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Semantics(
                        button: true,
                        label: 'Chat with driver',
                        child: InkWell(
                          onTap: _initiateLostFoundChat,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              LucideIcons.message_square,
                              color: context.colorScheme.onSurface,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                  SafetyReportButton(
                    driverName:
                        _counterpartyData?.name ??
                        ride?.displayDriverName ??
                        snapshot?.displayDriverName ??
                        '',
                    vehiclePlate:
                        ride?.vehiclePlate ?? snapshot?.plateNumber ?? '',
                    vehicleType:
                        ride?.vehicleType ?? snapshot?.vehicleType ?? '',
                    bookingReference:
                        snapshot?.bookingReference ??
                        widget.ride?.bookingReference ??
                        '',
                    rideId: rideId,
                    trackRepository: widget.trackRepository,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: context.colorScheme.outlineVariant,
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          statusSubtitle,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(
                      height: 1,
                      color: context.colorScheme.outlineVariant,
                    ),
                  ),
                  CompactRouteTimeline(
                    pickup:
                        ride?.pickup ??
                        snapshot?.pickupName ??
                        'Pickup Location',
                    dropoff:
                        ride?.destination ??
                        snapshot?.dropoffName ??
                        'Destination Location',
                    pickupLabel: 'Pick up',
                    dropoffLabel: 'Drop off',
                  ),
                ],
              ),
            ),

            if (isCompleted) ...[
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.goNamed(HomeRoutes.home),
                  child: const Text('Done'),
                ),
              ),
            ],
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
