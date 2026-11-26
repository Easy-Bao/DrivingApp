import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
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
    this.onBackPressed,
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
  final VoidCallback? onBackPressed;
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
    if (!widget.isSendingRequest &&
        widget.isChoosingDriver &&
        widget.requestedDriver == null) {
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
    final requestedDriver = widget.requestedDriver;
    final drivers = {
      for (final driver in widget.availability.drivers)
        if (widget.isChoosingDriver || readyOffers.containsKey(driver.id))
          driver.id: driver,
      if (!widget.isChoosingDriver && requestedDriver != null)
        requestedDriver.id: requestedDriver,
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
    final notice = widget.notice;
    final onBackPressed = widget.onBackPressed;

    final colors = context.colorScheme;
    final hairline = colors.outlineVariant.withValues(alpha: 0.7);
    final primaryButtonStyle =
        FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          elevation: 0,
          enableFeedback: false,
          splashFactory: NoSplash.splashFactory,
          minimumSize: const Size.fromHeight(AppSize.controlHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          textStyle: context.textStyles.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? colors.onPrimary.withValues(alpha: 0.16)
                : Colors.transparent,
          ),
        );

    return Material(
      key: const ValueKey('finding-driver-nearby-panel'),
      color: colors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.sheet),
        ),
        side: BorderSide(color: colors.outlineVariant),
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
                padding: const EdgeInsets.fromLTRB(
                  AppLayout.pagePadding,
                  AppSpacing.md,
                  AppLayout.pagePadding,
                  AppSpacing.md,
                ),
                sliver: SliverList.list(
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    if (notice != null) ...[
                      Semantics(
                        liveRegion: true,
                        child: Text(
                          notice,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
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
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatPesoAmount(widget.fare),
                                style: context.textStyles.titleMedium?.tabular
                                    .copyWith(
                                      color: colors.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      widget.isChoosingDriver
                          ? 'Select a driver, then send your request.'
                          : widget.isSendingRequest
                          ? 'Sending your request…'
                          : 'Your request was sent. Waiting for the driver to accept.',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    if (widget.isChoosingDriver &&
                        driverIds.isEmpty &&
                        error == null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.onSurface,
                              key: const ValueKey('nearby-drivers-loading'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Looking nearby',
                                  style: context.textStyles.titleSmall
                                      ?.copyWith(
                                        color: colors.onSurface,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.availability.hasLoaded
                                      ? 'No drivers available yet. We’ll keep checking nearby.'
                                      : 'Available drivers will appear here.',
                                  style: context.textStyles.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        widget.availability.hasLoaded
                            ? 'Driver availability could not be refreshed. Showing the last result.'
                            : widget.isChoosingDriver
                            ? 'Couldn’t load nearby drivers. We’ll keep trying.'
                            : 'Nearby drivers could not be loaded. Your ride request is still active.',
                        key: const ValueKey('nearby-drivers-error'),
                        style: context.textStyles.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: widget.onRetry,
                          style:
                              TextButton.styleFrom(
                                foregroundColor: colors.onSurface,
                                enableFeedback: false,
                                splashFactory: NoSplash.splashFactory,
                              ).copyWith(
                                overlayColor: WidgetStateProperty.resolveWith(
                                  (states) =>
                                      states.contains(WidgetState.focused)
                                      ? colors.primary.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                ),
                              ),
                          child: const Text('Try again'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (driverIds.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppLayout.pagePadding,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Divider(height: 1, color: hairline),
                  ),
                ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppLayout.pagePadding,
                ),
                sliver: SliverList.separated(
                  itemCount: driverIds.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: hairline),
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
                padding: const EdgeInsets.fromLTRB(
                  AppLayout.pagePadding,
                  AppSpacing.md,
                  AppLayout.pagePadding,
                  AppSpacing.lg,
                ),
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
                          style: primaryButtonStyle,
                          child: Text(
                            _requestSubmitted
                                ? 'Sending request…'
                                : 'Request driver',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        if (onBackPressed != null)
                          _buildChoosingFooterActions(
                            context,
                            busy: busy,
                            onBack: onBackPressed,
                            onCancel: widget.onCancelPressed,
                            isCanceling: widget.isCanceling,
                          )
                        else
                          TextButton(
                            onPressed: busy ? null : widget.onCancelPressed,
                            style: _secondaryTextButtonStyle(
                              colors.onSurfaceVariant,
                              colors.primary,
                            ),
                            child: const Text('Back to trip'),
                          ),
                      ] else if (widget.isChoosingDriver) ...[
                        FilledButton(
                          onPressed: busy
                              ? null
                              : (onBackPressed ?? widget.onCancelPressed),
                          style: primaryButtonStyle,
                          child: const Text('Back to trip'),
                        ),
                        if (onBackPressed != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          TextButton(
                            key: const ValueKey('nearby-drivers-cancel-search'),
                            onPressed: busy ? null : widget.onCancelPressed,
                            style: _secondaryTextButtonStyle(
                              colors.error,
                              colors.error,
                            ),
                            child: Text(
                              widget.isCanceling
                                  ? 'Cancelling…'
                                  : 'Cancel search',
                            ),
                          ),
                        ],
                      ] else
                        FilledButton(
                          onPressed: busy ? null : widget.onCancelPressed,
                          style: primaryButtonStyle,
                          child: Text(
                            widget.isCanceling
                                ? 'Cancelling…'
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

  ButtonStyle _secondaryTextButtonStyle(Color foreground, Color focusColor) {
    return TextButton.styleFrom(
      foregroundColor: foreground,
      enableFeedback: false,
      splashFactory: NoSplash.splashFactory,
      minimumSize: const Size.fromHeight(AppSize.minimumTouchTarget),
    ).copyWith(
      overlayColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? focusColor.withValues(alpha: 0.12)
            : Colors.transparent,
      ),
    );
  }

  Widget _buildChoosingFooterActions(
    BuildContext context, {
    required bool busy,
    required VoidCallback onBack,
    required VoidCallback onCancel,
    required bool isCanceling,
  }) {
    final colors = context.colorScheme;
    final backButton = TextButton(
      onPressed: busy ? null : onBack,
      style: _secondaryTextButtonStyle(colors.onSurfaceVariant, colors.primary),
      child: const Text('Back to trip'),
    );
    final cancelButton = TextButton(
      key: const ValueKey('nearby-drivers-cancel-search'),
      onPressed: busy ? null : onCancel,
      style: _secondaryTextButtonStyle(colors.error, colors.error),
      child: Text(isCanceling ? 'Cancelling…' : 'Cancel search'),
    );
    final stack =
        MediaQuery.sizeOf(context).width < 320 ||
        MediaQuery.textScalerOf(context).scale(14) > 21;
    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [backButton, cancelButton],
      );
    }
    return Row(
      children: [
        Expanded(child: backButton),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: cancelButton),
      ],
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
    final colors = context.colorScheme;
    final resolvedDriver = driver;
    final resolvedOffer = offer;
    final selectCallback = onSelectDriver;
    final rating = resolvedOffer?.driverRating ?? resolvedDriver?.rating;
    final canSelect = selectCallback != null && resolvedDriver != null;
    final driverDisplayName =
        resolvedOffer?.displayDriverName ??
        resolvedDriver?.displayName ??
        'Driver';
    final vehicleSummary =
        resolvedOffer?.vehicleSummary ?? resolvedDriver?.vehicleSummary ?? '';

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? colors.primary : colors.outlineVariant,
                ),
              ),
              child: AppNetworkImage(
                imageUrl: resolvedDriver?.avatarUrl,
                width: 40,
                height: 40,
                borderRadius: BorderRadius.circular(20),
                fallbackIcon: LucideIcons.user_round,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driverDisplayName,
                    style: context.textStyles.titleSmall?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicleSummary,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (resolvedDriver != null)
                        Text(
                          '${resolvedDriver.etaMinutes} min · ${DistanceFormatter.fromKilometers(resolvedDriver.distanceKm)}',
                          style: context.textStyles.bodySmall?.tabular.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      if (rating != null && rating > 0)
                        Text(
                          'Rating ${rating.toStringAsFixed(1)}',
                          style: context.textStyles.bodySmall?.tabular.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (canSelect) ...[
              const SizedBox(width: AppSpacing.sm),
              Icon(
                isSelected ? LucideIcons.circle_check : LucideIcons.circle,
                size: 20,
                color: isSelected ? colors.primary : colors.outlineVariant,
              ),
            ],
          ],
        ),
        if (!canSelect) const SizedBox(height: 10),
        if (resolvedOffer case final BookingOffer readyOffer when !canSelect)
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                'Accepted fare · ${formatPesoAmount(readyOffer.proposedFare)}',
                style: context.textStyles.bodyMedium?.tabular.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              FilledButton(
                onPressed: isBusy ? null : () => onChoose(readyOffer),
                style:
                    FilledButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      elevation: 0,
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.focused)
                            ? colors.onPrimary.withValues(alpha: 0.16)
                            : Colors.transparent,
                      ),
                    ),
                child: Text(isAccepting ? 'Confirming…' : 'Choose driver'),
              ),
            ],
          )
        else if (!canSelect)
          Text(
            'Awaiting response',
            style: context.textStyles.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
      ],
    );
    if (!canSelect) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: details,
      );
    }
    return Semantics(
      button: true,
      selected: isSelected,
      enabled: !isBusy,
      label: 'Select ${resolvedDriver.displayName}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: isBusy ? null : () => selectCallback(resolvedDriver),
          borderRadius: BorderRadius.circular(AppRadius.md),
          enableFeedback: false,
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.focused)
                ? colors.primary.withValues(alpha: 0.08)
                : Colors.transparent,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: details,
          ),
        ),
      ),
    );
  }
}
