import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_offer.dart';
import 'package:passenger/src/features/booking/domain/entities/driver.dart';
import 'package:passenger/src/features/booking/presentation/bloc/nearby_drivers/nearby_drivers_cubit.dart';

class const FindingDriverNearbyPanel({
  super.key,
  required this.availability,
  required this.offers,
  required this.fare,
  required this.onRefresh,
  required this.onSelectDriver,
  this.isChoosingDriver = false,
  required this.onAcceptOfferPressed,
  required this.onCancelPressed,
  this.acceptingOfferId,
  this.isCanceling = false,
  this.isSendingRequest = false,
  this.refreshError,
  this.notice,
}) extends StatelessWidget {
  final NearbyDriversState availability;
  final List<BookingOffer> offers;
  final double fare;
  final VoidCallback onRefresh;
  final ValueChanged<Driver> onSelectDriver;
  final bool isChoosingDriver;
  final ValueChanged<BookingOffer> onAcceptOfferPressed;
  final VoidCallback onCancelPressed;
  final String? acceptingOfferId;
  final bool isCanceling;
  final bool isSendingRequest;
  final String? refreshError;
  final String? notice;

  @override
  Widget build(BuildContext context) {
    final readyOffers = {
      for (final offer in offers.where((offer) => offer.status == 'pending'))
        offer.driverId: offer,
    };
    final drivers = {
      for (final driver in availability.drivers) driver.id: driver,
    };
    final driverIds = {
      ...readyOffers.keys,
      ...drivers.keys,
    }.toList(growable: false);
    final error = availability.errorMessage ?? refreshError;

    return Material(
      key: const ValueKey('finding-driver-nearby-panel'),
      color: context.colorScheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.65,
          ),
          child: CustomScrollView(
            shrinkWrap: true,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                sliver: SliverList.list(
                  children: [
                    if (notice != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          notice!,
                          style: context.textStyles.bodyMedium,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nearby drivers',
                                style: context.textStyles.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatPesoAmount(fare),
                                style: context.textStyles.titleMedium?.copyWith(
                                  color: context.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh nearby drivers',
                          onPressed: availability.isLoading ? null : onRefresh,
                          icon: const Icon(LucideIcons.refresh_cw, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isChoosingDriver
                          ? 'Select a driver. They’ll confirm your ride.'
                          : isSendingRequest
                          ? 'Sending your request…'
                          : 'Choose a driver once they accept your fare.',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (!availability.hasLoaded &&
                        driverIds.isEmpty &&
                        error == null) ...[
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: context.colorScheme.primary,
                              key: const ValueKey('nearby-drivers-loading'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Looking nearby',
                                  style: context.textStyles.titleSmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Available drivers will appear here.',
                                  style: context.textStyles.bodySmall?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        availability.hasLoaded
                            ? 'Driver availability could not be refreshed. Showing the last result.'
                            : isChoosingDriver
                            ? 'Couldn’t load nearby drivers. Try refreshing.'
                            : 'Nearby drivers could not be loaded. Your ride request is still active.',
                        key: const ValueKey('nearby-drivers-error'),
                        style: context.textStyles.bodySmall,
                      ),
                      TextButton(
                        onPressed: onRefresh,
                        child: const Text('Try again'),
                      ),
                    ] else if (availability.hasLoaded && driverIds.isEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'No drivers available nearby right now. We’ll keep checking for you.',
                        style: context.textStyles.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: driverIds.length,
                  separatorBuilder: (_, _) => const Divider(height: 24),
                  itemBuilder: (context, index) {
                    final id = driverIds[index];
                    return _DriverRow(
                      key: ValueKey('nearby-driver-$id'),
                      driver: drivers[id],
                      offer: readyOffers[id],
                      isBusy:
                          acceptingOfferId != null ||
                          isCanceling ||
                          isSendingRequest,
                      isAccepting:
                          acceptingOfferId != null &&
                          acceptingOfferId == readyOffers[id]?.offerId,
                      onChoose: onAcceptOfferPressed,
                      onSelectDriver: isChoosingDriver ? onSelectDriver : null,
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: TextButton(
                    onPressed: isCanceling || acceptingOfferId != null
                        ? null
                        : onCancelPressed,
                    child: Text(
                      isCanceling
                          ? 'Cancelling…'
                          : isChoosingDriver
                          ? 'Back to trip'
                          : 'Cancel request',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _DriverRow({
  super.key,
  this.driver,
  this.offer,
  required this.isBusy,
  required this.isAccepting,
  required this.onChoose,
  this.onSelectDriver,
}) extends StatelessWidget {
  final Driver? driver;
  final BookingOffer? offer;
  final bool isBusy;
  final bool isAccepting;
  final ValueChanged<BookingOffer> onChoose;
  final ValueChanged<Driver>? onSelectDriver;

  @override
  Widget build(BuildContext context) {
    final rating = offer?.driverRating ?? driver?.rating;
    final canSelect = onSelectDriver != null && driver != null;
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppNetworkImage(
              imageUrl: driver?.avatarUrl,
              width: 40,
              height: 40,
              borderRadius: BorderRadius.circular(20),
              fallbackIcon: LucideIcons.user_round,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer?.displayDriverName ?? driver!.displayName,
                    style: context.textStyles.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer?.vehicleSummary ?? driver!.vehicleSummary,
                    style: context.textStyles.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (driver != null)
                        Text(
                          '${driver!.etaMinutes} min · ${DistanceFormatter.fromKilometers(driver!.distanceKm)}',
                          style: context.textStyles.bodySmall,
                        ),
                      if (rating != null && rating > 0)
                        Text(
                          'Rating ${rating.toStringAsFixed(1)}',
                          style: context.textStyles.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (canSelect) ...[
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevron_right,
                size: 20,
                color: context.colorScheme.primary,
              ),
            ],
          ],
        ),
        if (!canSelect) const SizedBox(height: 8),
        if (offer case final BookingOffer readyOffer when !canSelect)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Accepted fare · ${formatPesoAmount(readyOffer.proposedFare)}',
                style: context.textStyles.bodyMedium,
              ),
              FilledButton(
                onPressed: isBusy ? null : () => onChoose(readyOffer),
                child: Text(isAccepting ? 'Confirming…' : 'Choose driver'),
              ),
            ],
          )
        else if (!canSelect)
          Text(
            'Available nearby · Awaiting response',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
    if (!canSelect) return details;
    return Semantics(
      button: true,
      enabled: !isBusy,
      label: 'Select ${driver!.displayName}',
      child: InkWell(
        onTap: isBusy ? null : () => onSelectDriver!(driver!),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: details,
        ),
      ),
    );
  }
}
