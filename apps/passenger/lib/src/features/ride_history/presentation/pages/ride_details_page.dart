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
import 'package:passenger/src/features/ride_history/presentation/widgets/ride_details_sections.dart';
import 'package:passenger/src/features/ride_history/ride_history.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';
import 'package:skeletonizer/skeletonizer.dart';
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
          child: snapshot == null && ride == null
              ? _buildInitialReceiptState(context, state, rideId)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.errorMessage case final errorMessage?)
                      if (rideId != null) ...[
                        AppErrorBanner(
                          message: errorMessage,
                          onRetry: () => unawaited(
                            _detailsCubit.load(rideId, force: true),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                    if (reference.trim().isNotEmpty) ...[
                      TripReference(
                        id: reference,
                        expanded: true,
                        compact: true,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                    RideDetailsDriverSection(
                      driverName: driverName,
                      vehicleSummary:
                          ride?.displayVehicleSummary ??
                          snapshot?.displayVehicleSummary ??
                          'Vehicle details unavailable',
                      showLostFoundChat: state.canContactCounterparty,
                      canCallDriver:
                          counterparty?.phone.trim().isNotEmpty == true,
                      contactError: _contactError,
                      onMessageDriver: () =>
                          unawaited(_initiateLostFoundChat(state)),
                      onCallDriver: () => unawaited(_callDriver(state)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xl,
                      ),
                      child: Divider(height: 1, color: hairline),
                    ),
                    RideDetailsRouteSection(
                      statusLabel: statusLabel,
                      isCompleted: isCompleted,
                      pickupLabel:
                          ride?.pickup ??
                          snapshot?.pickupName ??
                          'Pickup location',
                      dropoffLabel:
                          ride?.destination ??
                          snapshot?.dropoffName ??
                          'Destination location',
                      pickupLatitude:
                          ride?.pickupLat ?? snapshot?.pickupLatitude,
                      pickupLongitude:
                          ride?.pickupLng ?? snapshot?.pickupLongitude,
                      dropoffLatitude:
                          ride?.destLat ?? snapshot?.dropoffLatitude,
                      dropoffLongitude:
                          ride?.destLng ?? snapshot?.dropoffLongitude,
                      distanceKm: snapshot?.distanceKm,
                      durationMinutes: snapshot?.durationMinutes,
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
                              style: context.textStyles.titleSmall?.tabular
                                  .copyWith(
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
                                  side: BorderSide(
                                    color: colors.outlineVariant,
                                  ),
                                  backgroundColor:
                                      colors.surfaceContainerLowest,
                                  enableFeedback: false,
                                  splashFactory: NoSplash.splashFactory,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.md,
                                    ),
                                  ),
                                ).copyWith(
                                  overlayColor: WidgetStateProperty.resolveWith(
                                    (states) =>
                                        states.contains(WidgetState.focused)
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
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                        child: Divider(height: 1, color: hairline),
                      ),
                      RideDetailsFareBreakdown(snapshot: snapshot, fare: fare),
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
                                    ride?.vehiclePlate ??
                                    snapshot?.plateNumber ??
                                    '',
                                vehicleType:
                                    ride?.vehicleType ??
                                    snapshot?.vehicleType ??
                                    '',
                                trackRepository: widget.trackRepository,
                              ),
                        style:
                            TextButton.styleFrom(
                              foregroundColor: colors.onSurfaceVariant,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                              ),
                              minimumSize: const Size(
                                0,
                                AppSize.minimumTouchTarget,
                              ),
                              enableFeedback: false,
                              splashFactory: NoSplash.splashFactory,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
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

  Widget _buildInitialReceiptState(
    BuildContext context,
    RideDetailsState state,
    String? rideId,
  ) {
    if (state.isLoading) {
      return const ExcludeSemantics(
        child: Skeletonizer.zone(
          key: ValueKey<String>('passenger-ride-details-loading-skeleton'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Bone.circle(size: 44),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Bone.text(width: 140, fontSize: 16),
                        SizedBox(height: 6),
                        Bone.text(width: 110, fontSize: 12),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xxl),
              Bone.square(
                size: 180,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
              ),
              SizedBox(height: AppSpacing.xl),
              Bone.multiText(lines: 3, fontSize: 14),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
      child: AppRetryErrorView(
        title: 'Unable to load receipt',
        message:
            state.errorMessage ?? 'Trip details are unavailable right now.',
        onRetry: rideId == null
            ? () {}
            : () => unawaited(_detailsCubit.load(rideId, force: true)),
      ),
    );
  }
}
