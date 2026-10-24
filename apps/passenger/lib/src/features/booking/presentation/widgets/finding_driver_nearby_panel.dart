import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/booking/domain/entities/booking_offer.dart';
import 'package:passenger/src/features/booking/domain/entities/driver.dart';
import 'package:passenger/src/features/booking/presentation/bloc/nearby_drivers/nearby_drivers_cubit.dart';

class FindingDriverNearbyPanel extends StatefulWidget {
  const FindingDriverNearbyPanel({
    super.key,
    required this.availability,
    required this.offers,
    required this.fare,
    required this.onRetry,
    required this.onSelectDriver,
    this.isChoosingDriver = false,
    required this.onAcceptOfferPressed,
    required this.onCancelPressed,
    this.acceptingOfferId,
    this.isCanceling = false,
    this.isSendingRequest = false,
    this.refreshError,
    this.notice,
    this.requestedDriver,
  });
  final NearbyDriversState availability;
  final List<BookingOffer> offers;
  final double fare;
  final VoidCallback onRetry;
  final ValueChanged<Driver> onSelectDriver;
  final bool isChoosingDriver;
  final ValueChanged<BookingOffer> onAcceptOfferPressed;
  final VoidCallback onCancelPressed;
  final String? acceptingOfferId;
  final bool isCanceling;
  final bool isSendingRequest;
  final String? refreshError;
  final String? notice;
  final Driver? requestedDriver;

  @override
  State<FindingDriverNearbyPanel> createState() =>
      _FindingDriverNearbyPanelState();
}

class _FindingDriverNearbyPanelState extends State<FindingDriverNearbyPanel> {
  String? _selectedDriverId;
  bool _requestSubmitted = false;

  @override
  void didUpdateWidget(covariant FindingDriverNearbyPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isChoosingDriver && widget.isChoosingDriver) {
      _selectedDriverId = null;
      _requestSubmitted = false;
    }
    if (oldWidget.isSendingRequest &&
        !widget.isSendingRequest &&
        widget.isChoosingDriver) {
      _requestSubmitted = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final readyOffers = {
      for (final offer in widget.offers.where(
        (offer) => offer.status == 'pending',
      ))
        offer.driverId: offer,
    };
    final drivers = {
      for (final driver in widget.availability.drivers)
        if (widget.isChoosingDriver || readyOffers.containsKey(driver.id))
          driver.id: driver,
      if (!widget.isChoosingDriver && widget.requestedDriver != null)
        widget.requestedDriver!.id: widget.requestedDriver!,
    };
    final driverIds = {
      ...readyOffers.keys,
      ...drivers.keys,
    }.toList(growable: false);
    final selectedDriver = drivers[_selectedDriverId];
    final busy =
        widget.isCanceling ||
        widget.isSendingRequest ||
        (widget.isChoosingDriver && _requestSubmitted) ||
        widget.acceptingOfferId != null;
    final error = widget.availability.errorMessage ?? widget.refreshError;

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
                    if (widget.notice != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          widget.notice!,
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
                                widget.isChoosingDriver
                                    ? 'Nearby drivers'
                                    : 'Waiting for driver',
                                style: context.textStyles.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatPesoAmount(widget.fare),
                                style: context.textStyles.titleMedium?.copyWith(
                                  color: context.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.isChoosingDriver
                          ? 'Select a driver, then send your request.'
                          : widget.isSendingRequest
                          ? 'Sending your request…'
                          : 'Your request was sent. Waiting for the driver to accept.',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (widget.isChoosingDriver &&
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
                                  widget.availability.hasLoaded
                                      ? 'No drivers available yet. We’ll keep checking nearby.'
                                      : 'Available drivers will appear here.',
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
                        widget.availability.hasLoaded
                            ? 'Driver availability could not be refreshed. Showing the last result.'
                            : widget.isChoosingDriver
                            ? 'Couldn’t load nearby drivers. We’ll keep trying.'
                            : 'Nearby drivers could not be loaded. Your ride request is still active.',
                        key: const ValueKey('nearby-drivers-error'),
                        style: context.textStyles.bodySmall,
                      ),
                      TextButton(
                        onPressed: widget.onRetry,
                        child: const Text('Try again'),
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
                      isBusy: busy,
                      isAccepting:
                          widget.acceptingOfferId != null &&
                          widget.acceptingOfferId == readyOffers[id]?.offerId,
                      onChoose: widget.onAcceptOfferPressed,
                      onSelectDriver: widget.isChoosingDriver
                          ? (driver) =>
                                setState(() => _selectedDriverId = driver.id)
                          : null,
                      isSelected: id == _selectedDriverId,
                    );
                  },
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.isChoosingDriver && driverIds.isNotEmpty) ...[
                        FilledButton(
                          onPressed: busy || selectedDriver == null
                              ? null
                              : () {
                                  setState(() => _requestSubmitted = true);
                                  widget.onSelectDriver(selectedDriver);
                                },
                          child: Text(
                            _requestSubmitted
                                ? 'Sending request…'
                                : 'Request driver',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextButton(
                          onPressed: busy ? null : widget.onCancelPressed,
                          child: const Text('Back to trip'),
                        ),
                      ] else
                        FilledButton(
                          onPressed: busy ? null : widget.onCancelPressed,
                          child: Text(
                            widget.isCanceling
                                ? 'Cancelling…'
                                : widget.isChoosingDriver
                                ? 'Back to trip'
                                : 'Cancel request',
                          ),
                        ),
                    ],
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
  this.isSelected = false,
}) extends StatelessWidget {
  final Driver? driver;
  final BookingOffer? offer;
  final bool isBusy;
  final bool isAccepting;
  final ValueChanged<BookingOffer> onChoose;
  final ValueChanged<Driver>? onSelectDriver;
  final bool isSelected;

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
                isSelected ? LucideIcons.circle_check : LucideIcons.circle,
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
            'Awaiting response',
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
    if (!canSelect) return details;
    return Semantics(
      button: true,
      selected: isSelected,
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
