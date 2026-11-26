import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/app/navigation/floating_tab_bar.dart';
import 'package:passenger/src/app/navigation/widgets/active_booking_banner.dart';
import 'package:passenger/src/app/navigation/widgets/active_ride_banner.dart';
import 'package:passenger/src/app/navigation/widgets/pending_booking_banner.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_cubit.dart';
import 'package:passenger/src/features/active_ride/presentation/bloc/track_driver_state.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_draft.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger/src/features/inbox/presentation/bloc/inbox_cubit.dart';

class ShellTabBarSection extends StatelessWidget {
  const ShellTabBarSection({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.inboxCubit,
    required this.pagePosition,
    required this.trackCubit,
    required this.bookingBloc,
    required this.bookingDraftCubit,
    required this.dismissedBookingFailure,
    required this.onResumeRide,
    required this.onResumeMatchedRide,
    required this.onOpenFindingDriver,
    required this.onConfirmCancelDriverSearch,
    required this.onDismissBookingNotice,
    required this.onContinuePendingBooking,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final InboxCubit inboxCubit;
  final ValueListenable<double> pagePosition;
  final TrackDriverCubit? trackCubit;
  final BookingBloc? bookingBloc;
  final BookingDraftCubit? bookingDraftCubit;
  final BookingFailure? dismissedBookingFailure;
  final Future<void> Function() onResumeRide;
  final Future<void> Function(String? rideId) onResumeMatchedRide;
  final void Function(
    ActiveDriverSearch search, {
    BookingBloc? bookingBloc,
    bool resetFirst,
  })
  onOpenFindingDriver;
  final Future<void> Function(BookingBloc bookingBloc, String destinationName)
  onConfirmCancelDriverSearch;
  final void Function(BookingBloc bookingBloc, BookingFailure failure)
  onDismissBookingNotice;
  final Future<void> Function(
    BookingDraft draft,
    BookingDraftCubit draftCubit, {
    required TrackDriverState? trackState,
    required BookingBloc? bookingBloc,
  })
  onContinuePendingBooking;

  @override
  Widget build(BuildContext context) {
    final track = trackCubit;
    if (track == null) return _buildWithBooking();
    return BlocBuilder<TrackDriverCubit, TrackDriverState>(
      bloc: track,
      buildWhen: _shouldRebuildForTrackState,
      builder: (_, trackState) => _buildWithBooking(trackState: trackState),
    );
  }

  Widget _buildWithBooking({TrackDriverState? trackState}) {
    final booking = bookingBloc;
    if (booking == null) return _buildWithDraft(trackState: trackState);
    return BlocBuilder<BookingBloc, BookingState>(
      bloc: booking,
      buildWhen: (previous, current) =>
          _shouldRebuildForBookingState(booking, previous, current),
      builder: (_, bookingState) =>
          _buildWithDraft(trackState: trackState, bookingState: bookingState),
    );
  }

  Widget _buildWithDraft({
    TrackDriverState? trackState,
    BookingState? bookingState,
  }) {
    final draftCubit = bookingDraftCubit;
    if (draftCubit == null) {
      return _buildFloatingTabBar(
        trackState: trackState,
        bookingState: bookingState,
      );
    }
    return BlocBuilder<BookingDraftCubit, BookingDraftState>(
      bloc: draftCubit,
      buildWhen: (previous, current) => previous.draft != current.draft,
      builder: (_, draftState) => _buildFloatingTabBar(
        trackState: trackState,
        bookingState: bookingState,
        draft: draftState.draft,
      ),
    );
  }

  Widget _buildFloatingTabBar({
    TrackDriverState? trackState,
    BookingState? bookingState,
    BookingDraft? draft,
  }) {
    final booking = bookingBloc;
    final draftCubit = bookingDraftCubit;
    final Widget? banner =
        (trackState != null ? _buildActiveRideBanner(trackState) : null) ??
        (booking != null && bookingState != null
            ? _buildActiveBookingBanner(booking, bookingState)
            : null) ??
        (draftCubit != null && draft != null
            ? _buildPendingBookingBanner(
                draft: draft,
                draftCubit: draftCubit,
                trackState: trackState,
                bookingBloc: booking,
              )
            : null);

    return FloatingTabBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      inboxCubit: inboxCubit,
      pagePosition: pagePosition,
      activeRideBanner: banner,
    );
  }

  Widget? _buildActiveRideBanner(TrackDriverState trackState) {
    if (trackState.isTerminal || !trackState.isTracking) return null;

    final statusText = trackState.isInTransit
        ? 'Heading to Destination'
        : trackState.hasArrived
        ? 'Driver Has Arrived'
        : 'Driver is Picking You Up';

    return ActiveRideBanner(
      statusText: statusText,
      driverName: trackState.activeDriverName.isNotEmpty
          ? trackState.activeDriverName
          : 'Driver',
      vehicleInfo: [
        trackState.activeVehicleType,
        trackState.activeVehiclePlate,
      ].where((value) => value.trim().isNotEmpty).join(' • '),
      onResume: () => unawaited(onResumeRide()),
    );
  }

  Widget? _buildActiveBookingBanner(
    BookingBloc bookingBloc,
    BookingState state,
  ) {
    final activeSearch = bookingBloc.activeDriverSearch;
    switch (state) {
      case BookingInitial() || BookingCanceled():
        return null;
      case BookingDriverMatched(:final matchResult, :final rideId):
        return ActiveBookingBanner(
          title: 'Driver accepted',
          subtitle: '${matchResult.driverName} is on the way',
          tone: ActiveBookingBannerTone.matched,
          icon: LucideIcons.car,
          actionLabel: 'Resume Trip',
          showActionArrow: true,
          onAction: () => unawaited(onResumeMatchedRide(rideId)),
        );
      case BookingRideRecovered(:final rideId):
        return ActiveBookingBanner(
          title: 'Driver accepted',
          subtitle: 'Resume your trip to track your driver.',
          tone: ActiveBookingBannerTone.matched,
          icon: LucideIcons.car,
          actionLabel: 'Resume Trip',
          showActionArrow: true,
          onAction: () => unawaited(onResumeMatchedRide(rideId)),
        );
      case BookingSessionRecoveryInProgress(:final sessionId):
        return ActiveBookingBanner(
          title: sessionId.isEmpty
              ? 'Sending ride request'
              : 'Checking your request',
          subtitle:
              activeSearch?.trip.destination.name ??
              'Reconnecting to your ride request…',
          tone: ActiveBookingBannerTone.active,
          isLoading: true,
          actionLabel: activeSearch != null ? 'View' : null,
          showActionArrow: activeSearch != null,
          onAction: activeSearch == null
              ? null
              : () => onOpenFindingDriver(activeSearch),
        );
      case BookingSessionRecoveryFailure(:final message):
        return ActiveBookingBanner(
          title: 'Request needs attention',
          subtitle: message,
          tone: ActiveBookingBannerTone.error,
          icon: LucideIcons.circle_alert,
          actionLabel: 'Retry',
          onAction: () => bookingBloc.add(const RestoreActiveBookingEvent()),
        );
      case BookingSearching(
        :final isDirect,
        :final targetDriver,
        :final sessionId,
      ):
        final destination = activeSearch?.trip.destination.name;
        final title = sessionId == null
            ? 'Sending ride request'
            : isDirect
            ? 'Waiting for driver'
            : 'Searching for a driver';
        final subtitle = _waitingSubtitle(
          driverName: targetDriver?.displayName,
          destinationName: destination,
          fallback: sessionId == null
              ? 'Confirming your trip request…'
              : 'Waiting for a driver to respond',
        );
        return ActiveBookingBanner(
          title: title,
          subtitle: subtitle,
          tone: ActiveBookingBannerTone.active,
          isLoading: true,
          actionLabel: activeSearch != null ? 'View' : null,
          showActionArrow: activeSearch != null,
          onAction: activeSearch == null
              ? null
              : () => onOpenFindingDriver(activeSearch),
        );
      case BookingOffersReceived(
        :final offers,
        :final isDirect,
        :final targetDriver,
      ):
        final destination = activeSearch?.trip.destination.name;
        final title = offers.isNotEmpty
            ? '${offers.length} driver ${offers.length == 1 ? 'offer' : 'offers'}'
            : isDirect
            ? 'Waiting for driver'
            : 'Searching for a driver';
        final subtitle = _waitingSubtitle(
          driverName: targetDriver?.displayName,
          destinationName: destination,
          fallback: offers.isNotEmpty
              ? 'Tap to review available offers'
              : 'Waiting for a driver to accept',
        );
        return ActiveBookingBanner(
          title: title,
          subtitle: subtitle,
          tone: ActiveBookingBannerTone.active,
          isLoading: offers.isEmpty,
          icon: LucideIcons.car,
          actionLabel: activeSearch != null ? 'View' : null,
          showActionArrow: activeSearch != null,
          onAction: activeSearch == null
              ? null
              : () => onOpenFindingDriver(activeSearch),
        );
      case BookingFindingNearbyDrivers(:final trip, :final drivers):
        if (drivers.isNotEmpty) {
          return ActiveBookingBanner(
            title: 'Nearby drivers ready',
            subtitle: '${drivers.first.displayName} • ${trip.destination.name}',
            tone: ActiveBookingBannerTone.active,
            icon: LucideIcons.car,
            actionLabel: activeSearch != null ? 'View' : null,
            showActionArrow: activeSearch != null,
            onAction: activeSearch == null
                ? null
                : () => onOpenFindingDriver(activeSearch),
            onDismiss: () => unawaited(
              onConfirmCancelDriverSearch(bookingBloc, trip.destination.name),
            ),
          );
        }
        return ActiveBookingBanner(
          title: 'Looking for drivers',
          subtitle: 'To ${trip.destination.name}',
          tone: ActiveBookingBannerTone.active,
          isLoading: true,
          actionLabel: activeSearch != null ? 'View' : null,
          showActionArrow: activeSearch != null,
          onAction: activeSearch == null
              ? null
              : () => onOpenFindingDriver(activeSearch),
          onDismiss: () => unawaited(
            onConfirmCancelDriverSearch(bookingBloc, trip.destination.name),
          ),
        );
      case FindingNearestDriver(:final trip):
        return ActiveBookingBanner(
          title: 'Looking for drivers',
          subtitle: 'To ${trip.destination.name}',
          tone: ActiveBookingBannerTone.active,
          isLoading: true,
          actionLabel: activeSearch != null ? 'View' : null,
          showActionArrow: activeSearch != null,
          onAction: activeSearch == null
              ? null
              : () => onOpenFindingDriver(activeSearch),
        );
      case NearestDriverFound(:final driver, :final trip):
        return ActiveBookingBanner(
          title: 'Nearby drivers ready',
          subtitle: '${driver.displayName} • ${trip.destination.name}',
          tone: ActiveBookingBannerTone.active,
          icon: LucideIcons.car,
          actionLabel: activeSearch != null ? 'View' : null,
          showActionArrow: activeSearch != null,
          onAction: activeSearch == null
              ? null
              : () => onOpenFindingDriver(activeSearch),
        );
      case BookingFailure():
        if (!state.isNoDriverOrTimedOutFailure ||
            identical(dismissedBookingFailure, state)) {
          return null;
        }
        final retrySearch = bookingBloc.retryableDriverSearch;
        final destination = retrySearch?.trip.destination.name;
        final String title;
        final String subtitle;
        final IconData icon;
        final ActiveBookingBannerTone tone;
        if (state.isNoDriverFound) {
          title = 'No driver found';
          subtitle = destination == null
              ? 'No drivers available nearby. Try again.'
              : 'No drivers available for $destination.';
          icon = LucideIcons.search_x;
          tone = ActiveBookingBannerTone.error;
        } else if (state.isRequestExpired) {
          title = 'Driver timed out';
          subtitle = destination == null
              ? 'No driver accepted your request in time.'
              : 'No driver responded for $destination.';
          icon = LucideIcons.timer;
          tone = ActiveBookingBannerTone.warning;
        } else {
          title = 'Driver declined';
          subtitle = state.message;
          icon = LucideIcons.circle_alert;
          tone = ActiveBookingBannerTone.warning;
        }
        return ActiveBookingBanner(
          title: title,
          subtitle: subtitle,
          tone: tone,
          icon: icon,
          announceLiveRegion: true,
          actionLabel: retrySearch != null ? 'Retry' : null,
          onAction: retrySearch == null
              ? null
              : () => onOpenFindingDriver(
                  retrySearch,
                  bookingBloc: bookingBloc,
                  resetFirst: true,
                ),
          onDismiss: () => onDismissBookingNotice(bookingBloc, state),
        );
    }
  }

  Widget? _buildPendingBookingBanner({
    required BookingDraft draft,
    required BookingDraftCubit draftCubit,
    required TrackDriverState? trackState,
    required BookingBloc? bookingBloc,
  }) {
    if (trackState != null && !trackState.isTerminal && trackState.isTracking) {
      return null;
    }
    if (bookingBloc != null &&
        (bookingBloc.state.isBlockingBooking ||
            bookingBloc.hasActiveDriverSearch)) {
      return null;
    }
    return PendingBookingBanner(
      isAuthenticated: true,
      destinationName: draft.destination.name,
      onContinue: () => unawaited(
        onContinuePendingBooking(
          draft,
          draftCubit,
          trackState: trackState,
          bookingBloc: bookingBloc,
        ),
      ),
      onDismiss: draftCubit.clear,
    );
  }

  String _waitingSubtitle({
    String? driverName,
    String? destinationName,
    required String fallback,
  }) {
    final driver = driverName?.trim() ?? '';
    final destination = destinationName?.trim() ?? '';
    if (driver.isNotEmpty && destination.isNotEmpty) {
      return '$driver • $destination';
    }
    if (destination.isNotEmpty) return 'To $destination';
    if (driver.isNotEmpty) return 'Waiting for $driver';
    return fallback;
  }

  static bool _shouldRebuildForTrackState(
    TrackDriverState previous,
    TrackDriverState current,
  ) {
    return previous.isTerminal != current.isTerminal ||
        previous.isTracking != current.isTracking ||
        previous.isInTransit != current.isInTransit ||
        previous.hasArrived != current.hasArrived ||
        previous.activeDriverName != current.activeDriverName ||
        previous.activeVehicleType != current.activeVehicleType ||
        previous.activeVehiclePlate != current.activeVehiclePlate;
  }

  static bool _shouldRebuildForBookingState(
    BookingBloc bloc,
    BookingState previous,
    BookingState current,
  ) {
    if (previous.runtimeType != current.runtimeType) return true;
    return switch ((previous, current)) {
      (BookingInitial(), BookingInitial()) ||
      (BookingCanceled(), BookingCanceled()) => false,
      (
        BookingDriverMatched(
          rideId: final prevRideId,
          matchResult: final prevMatch,
        ),
        BookingDriverMatched(
          rideId: final currRideId,
          matchResult: final currMatch,
        ),
      ) =>
        prevRideId != currRideId ||
            prevMatch.driverName != currMatch.driverName,
      (
        BookingRideRecovered(rideId: final prevRideId),
        BookingRideRecovered(rideId: final currRideId),
      ) =>
        prevRideId != currRideId,
      (
        BookingSessionRecoveryInProgress(sessionId: final prevId),
        BookingSessionRecoveryInProgress(sessionId: final currId),
      ) =>
        prevId != currId,
      (
        BookingSessionRecoveryFailure(message: final prevMessage),
        BookingSessionRecoveryFailure(message: final currMessage),
      ) =>
        prevMessage != currMessage,
      (
        BookingSearching(
          isDirect: final prevDirect,
          targetDriver: final prevDriver,
          sessionId: final prevSessionId,
        ),
        BookingSearching(
          isDirect: final currDirect,
          targetDriver: final currDriver,
          sessionId: final currSessionId,
        ),
      ) =>
        prevDirect != currDirect ||
            prevDriver?.displayName != currDriver?.displayName ||
            prevSessionId != currSessionId,
      (
        BookingOffersReceived(
          offers: final prevOffers,
          isDirect: final prevDirect,
          targetDriver: final prevDriver,
        ),
        BookingOffersReceived(
          offers: final currOffers,
          isDirect: final currDirect,
          targetDriver: final currDriver,
        ),
      ) =>
        prevOffers.length != currOffers.length ||
            prevDirect != currDirect ||
            prevDriver?.displayName != currDriver?.displayName,
      (
        BookingFindingNearbyDrivers(
          trip: final prevTrip,
          drivers: final prevDrivers,
        ),
        BookingFindingNearbyDrivers(
          trip: final currTrip,
          drivers: final currDrivers,
        ),
      ) =>
        prevTrip.destination.name != currTrip.destination.name ||
            (prevDrivers.isEmpty ? '' : prevDrivers.first.displayName) !=
                (currDrivers.isEmpty ? '' : currDrivers.first.displayName),
      (
        FindingNearestDriver(trip: final prevTrip),
        FindingNearestDriver(trip: final currTrip),
      ) =>
        prevTrip.destination.name != currTrip.destination.name,
      (
        NearestDriverFound(driver: final prevDriver, trip: final prevTrip),
        NearestDriverFound(driver: final currDriver, trip: final currTrip),
      ) =>
        prevDriver.displayName != currDriver.displayName ||
            prevTrip.destination.name != currTrip.destination.name,
      (final BookingFailure prevFailure, final BookingFailure currFailure) =>
        !identical(prevFailure, currFailure) ||
            prevFailure != currFailure ||
            bloc.retryableDriverSearch != null,
      _ => true,
    };
  }
}
