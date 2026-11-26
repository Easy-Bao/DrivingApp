import 'dart:async';
import 'dart:developer' as developer;

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart' hide Route;
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/active_ride.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/chat/chat_routes.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_details/ride_details_cubit.dart';
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_details_map.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';
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
  late final bool _ownsDetailsCubit;
  String? _contactError;

  String? get _rideId =>
      widget.ride?.id ?? widget.initialRide?.id ?? widget.rideId;

  @override
  void initState() {
    super.initState();
    _ownsDetailsCubit = widget.detailsCubit == null;
    _detailsCubit =
        widget.detailsCubit ??
        RideDetailsCubit(
          repository: widget.trackRepository,
          sessionService: widget.sessionService,
          profileRepository: widget.profileRepository,
        );
    final rideId = _rideId;
    if (rideId != null) {
      unawaited(_detailsCubit.load(rideId));
      _loadReviewIfEligible(_detailsCubit.state);
    }
  }

  void _loadReviewIfEligible(RideDetailsState state) {
    if (state.hasLoadedReview ||
        state.isLoadingReview ||
        state.submittedReview != null ||
        state.reviewErrorMessage != null) {
      return;
    }
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

  @override
  void dispose() {
    if (_ownsDetailsCubit) {
      unawaited(_detailsCubit.close());
    }
    super.dispose();
  }

  Future<void> _initiateLostFoundChat(RideDetailsState state) async {
    final rideId = _rideId;
    final retrievedRideData = state.ride;
    if (rideId == null ||
        retrievedRideData == null ||
        state.passengerId.isEmpty) {
      return;
    }

    final driverId =
        state.counterparty?.userId ?? retrievedRideData.driverId ?? '';
    if (driverId.isEmpty) return;

    try {
      if (mounted) {
        unawaited(
          context.pushNamed(
            ChatRoutes.driverChat,
            extra: {
              'roomId': rideId,
              'userId': state.passengerId,
              'peerId': driverId,
              'peerName': SafeParse.toStringValue(
                state.counterparty?.name ?? retrievedRideData.driverName,
                'Driver',
              ),
            },
          ),
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Unable to open lost-and-found chat for ride $rideId.',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Widget _buildReceiptSummary(
    BuildContext context,
    RideSnapshot? snapshot,
    double? fare,
  ) {
    final colors = context.colorScheme;
    final cashReceivedAmount = snapshot?.cashReceivedAmount;
    final cashChangeAmount = snapshot?.cashChangeAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(
              child: Text(
                'Total fare',
                style: context.textStyles.bodyLarge?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Flexible(
              child: Text(
                fare == null ? 'Fare unavailable' : formatPesoAmount(fare),
                key: const ValueKey('receipt-total-fare'),
                textAlign: TextAlign.end,
                style: context.textStyles.titleLarge?.tabular.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Cash · ${_cashPaymentStatus(snapshot)}',
          style: context.textStyles.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        if (snapshot?.cashSettled == true &&
            cashReceivedAmount != null &&
            cashReceivedAmount > 0) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Cash received ${formatPesoAmount(cashReceivedAmount / 100)}'
            '${cashChangeAmount != null && cashChangeAmount > 0 ? ' · Change ${formatPesoAmount(cashChangeAmount / 100)}' : ''}',
            style: context.textStyles.bodySmall?.tabular.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Semantics(
      header: true,
      child: Text(
        label,
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.85,
        ),
      ),
    );
  }

  Widget _buildContactButton(
    BuildContext context, {
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colors = context.colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      style:
          IconButton.styleFrom(
            backgroundColor: colors.surfaceContainerLowest,
            foregroundColor: colors.onSurface,
            side: BorderSide(color: colors.outlineVariant),
            shape: const CircleBorder(),
            enableFeedback: false,
            splashFactory: NoSplash.splashFactory,
          ).copyWith(
            overlayColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.focused)
                  ? colors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
            ),
          ),
      icon: Icon(icon, size: 18),
    );
  }

  Future<void> _callDriver(RideDetailsState state) async {
    final counterparty = state.counterparty;
    if (!state.canContactCounterparty ||
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
    final date =
        snapshot?.completedAt ??
        ride?.recordedAt ??
        DateTime.tryParse(ride?.date ?? '');
    if (date == null) {
      final fallback = ride?.date.trim() ?? '';
      return fallback.isNotEmpty ? fallback : null;
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
    return BlocConsumer<RideDetailsCubit, RideDetailsState>(
      bloc: _detailsCubit,
      listenWhen: (previous, current) =>
          previous.ride != current.ride || previous.rideId != current.rideId,
      listener: (_, state) => _loadReviewIfEligible(state),
      builder: (context, state) {
        final ride = widget.ride;
        final snapshot = state.ride ?? widget.initialRide;
        final counterparty = state.counterparty;
        final showLostFoundChat = state.canContactCounterparty;
        final rideId = _rideId;
        final fare =
            snapshot?.farePesos ??
            (ride == null
                ? null
                : double.tryParse(
                    ride.price.replaceAll(RegExp(r'[^0-9.\-]'), ''),
                  ));
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
            counterparty?.name ??
            ride?.displayDriverName ??
            snapshot?.displayDriverName ??
            'Driver';

        final colors = context.colorScheme;
        final hairline = colors.outlineVariant.withValues(alpha: 0.7);
        final statusLabel = switch (status) {
          'completed' => 'Completed',
          'cancelled' || 'canceled' => 'Canceled',
          'assigned' || 'accepted' => 'Awaiting pickup',
          'arrived' => 'At pickup',
          'in_transit' => 'In progress',
          'requested' => 'Requested',
          _ => 'Unknown',
        };

        return TripReceiptLayout(
          dateLabel: _receiptDate(context, snapshot, ride),
          onBack: () => context.pop(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.errorMessage case final errorMessage?)
                if (rideId != null) ...[
                  AppErrorBanner(
                    message: errorMessage,
                    onRetry: () =>
                        unawaited(_detailsCubit.load(rideId, force: true)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              if (reference.trim().isNotEmpty) ...[
                TripReference(id: reference, expanded: true, compact: true),
                const SizedBox(height: AppSpacing.lg),
              ],
              _buildSectionLabel(context, 'DRIVER'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _driverInitials(driverName),
                      style: context.textStyles.titleSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driverName,
                          style: context.textStyles.titleMedium?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ride?.displayVehicleSummary ??
                              snapshot?.displayVehicleSummary ??
                              'Vehicle details unavailable',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showLostFoundChat) ...[
                    const SizedBox(width: AppSpacing.sm),
                    _buildContactButton(
                      context,
                      tooltip: 'Message driver',
                      icon: LucideIcons.message_circle,
                      onPressed: () => unawaited(_initiateLostFoundChat(state)),
                    ),
                  ],
                  if (showLostFoundChat &&
                      counterparty?.phone.trim().isNotEmpty == true) ...[
                    const SizedBox(width: AppSpacing.xs),
                    _buildContactButton(
                      context,
                      tooltip: 'Call driver',
                      icon: LucideIcons.phone,
                      onPressed: () => unawaited(_callDriver(state)),
                    ),
                  ],
                ],
              ),
              if (_contactError case final contactError?) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  contactError,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: colors.error,
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Divider(height: 1, color: hairline),
              ),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  _buildSectionLabel(context, 'ROUTE'),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: isCompleted
                            ? context.semanticColors.success.withValues(
                                alpha: 0.4,
                              )
                            : colors.outlineVariant,
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: isCompleted
                            ? context.semanticColors.success
                            : colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (pickupLatitude != null &&
                  pickupLongitude != null &&
                  dropoffLatitude != null &&
                  dropoffLongitude != null) ...[
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SizedBox(
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
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (snapshot?.distanceKm != null ||
                  snapshot?.durationMinutes != null) ...[
                Text(
                  [
                    if (snapshot?.distanceKm case final distance?)
                      distance < 1
                          ? '${(distance * 1000).round()} m'
                          : '${distance.toStringAsFixed(1)} km',
                    if (snapshot?.durationMinutes case final duration?)
                      '${duration.round()} min',
                  ].join(' · '),
                  style: context.textStyles.labelSmall?.tabular.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              CompactRouteTimeline(
                pickup:
                    ride?.pickup ?? snapshot?.pickupName ?? 'Pickup location',
                dropoff:
                    ride?.destination ??
                    snapshot?.dropoffName ??
                    'Destination location',
              ),
              if (isCompleted &&
                  snapshot != null &&
                  snapshot.driverId?.isNotEmpty == true &&
                  rideId != null) ...[
                if (state.submittedReview case final review?) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xl,
                    ),
                    child: Divider(height: 1, color: hairline),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ride rating',
                          style: context.textStyles.bodyLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        review.rating.toStringAsFixed(0),
                        style: context.textStyles.titleSmall?.tabular.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Icon(
                        Icons.star_rounded,
                        size: 18,
                        color: context.semanticColors.rating,
                      ),
                    ],
                  ),
                ] else if (widget.showRatingAction &&
                    state.hasLoadedReview &&
                    !state.isLoadingReview &&
                    state.reviewErrorMessage == null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        await context.pushNamed(
                          RideHistoryRoutes.tripCompletion,
                          extra: (ride: snapshot, returnToReceipt: true),
                        );
                        if (mounted) {
                          await _detailsCubit.loadMyReview(
                            rideId,
                            refresh: true,
                          );
                        }
                      },
                      style:
                          TextButton.styleFrom(
                            foregroundColor: colors.onSurface,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                            ),
                            minimumSize: const Size(
                              0,
                              AppSize.minimumTouchTarget,
                            ),
                            side: BorderSide(color: colors.outlineVariant),
                            backgroundColor: colors.surfaceContainerLowest,
                            enableFeedback: false,
                            splashFactory: NoSplash.splashFactory,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ).copyWith(
                            overlayColor: WidgetStateProperty.resolveWith(
                              (states) => states.contains(WidgetState.focused)
                                  ? colors.primary.withValues(alpha: 0.12)
                                  : Colors.transparent,
                            ),
                          ),
                      icon: Icon(
                        Icons.star_outline_rounded,
                        size: 18,
                        color: colors.onSurface,
                      ),
                      label: const Text('Rate this ride'),
                    ),
                  ),
                ],
              ],
              if (isCompleted) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Divider(height: 1, color: hairline),
                ),
                _buildSectionLabel(context, 'FARE BREAKDOWN'),
                const SizedBox(height: AppSpacing.md),
                _buildReceiptSummary(context, snapshot, fare),
              ],
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.xl,
                  bottom: AppSpacing.sm,
                ),
                child: Divider(height: 1, color: hairline),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
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
                  style:
                      TextButton.styleFrom(
                        foregroundColor: colors.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        minimumSize: const Size(0, AppSize.minimumTouchTarget),
                        enableFeedback: false,
                        splashFactory: NoSplash.splashFactory,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.focused)
                              ? colors.primary.withValues(alpha: 0.12)
                              : Colors.transparent,
                        ),
                      ),
                  icon: const Icon(LucideIcons.flag, size: 16),
                  label: const Text('Report an issue'),
                ),
              ),
            ],
          ),
        );
      },
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
