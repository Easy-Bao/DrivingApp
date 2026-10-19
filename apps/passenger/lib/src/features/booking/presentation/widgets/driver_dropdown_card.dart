import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/driver_profile/presentation/widgets/driver_profile_details_sheet.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DriverDropdownCard extends StatefulWidget {
  final DriverModel driver;
  final bool isNearestDriver;
  final bool isProfileVisible;
  final VoidCallback onViewFullProfilePressed;
  final VoidCallback onProfileBackPressed;
  final VoidCallback onSelectDriverPressed;
  final VoidCallback onCloseDropdownPressed;
  final DriverProfileRepository profileRepository;
  final BookingBloc? bookingBloc;

  const DriverDropdownCard({
    super.key,
    required this.driver,
    required this.isNearestDriver,
    this.isProfileVisible = false,
    required this.onViewFullProfilePressed,
    required this.onProfileBackPressed,
    required this.onSelectDriverPressed,
    required this.onCloseDropdownPressed,
    required this.profileRepository,
    this.bookingBloc,
  });

  @override
  State<DriverDropdownCard> createState() => _DriverDropdownCardState();
}

class _DriverDropdownCardState()
    extends State<DriverDropdownCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dropdownAnimationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _dropdownAnimationController = AnimationController(
      vsync: this,
      duration: AppTransitions.pushDuration,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _dropdownAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _fadeAnimation = CurvedAnimation(
      parent: _dropdownAnimationController,
      curve: Curves.easeOutCubic,
    );

    unawaited(_dropdownAnimationController.forward());
    _requestDriverReviews();
  }

  @override
  void didUpdateWidget(covariant DriverDropdownCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driver.id != widget.driver.id) _requestDriverReviews();
  }

  BookingBloc? get _bookingBloc {
    if (widget.bookingBloc != null) return widget.bookingBloc;
    try {
      return context.read<BookingBloc>();
    } catch (_) {
      return null;
    }
  }

  void _requestDriverReviews() {
    _bookingBloc?.add(LoadDriverReviewsEvent(driverId: widget.driver.id));
  }

  ({List<DriverReview> reviews, bool isLoading}) _feedbackForState(
    BookingState state,
  ) {
    if (state is! NearestDriverFound ||
        state.reviewsDriverId != widget.driver.id) {
      return (reviews: const [], isLoading: true);
    }

    final visibleReviews = state.reviews
        .where((review) => review.comment.isNotEmpty)
        .take(6)
        .toList(growable: false);
    if (state.isLoadingReviews || visibleReviews.isNotEmpty) {
      return (reviews: visibleReviews, isLoading: state.isLoadingReviews);
    }

    final fallbackFeedback = widget.driver.recentFeedback?.trim();
    if (fallbackFeedback == null || fallbackFeedback.isEmpty) {
      return (reviews: const [], isLoading: false);
    }
    return (
      reviews: [
        DriverReview(
          passengerName: 'Passenger',
          comment: fallbackFeedback,
          rating: widget.driver.rating,
        ),
      ],
      isLoading: false,
    );
  }

  Widget _buildReviewCountLabel() {
    final bloc = _bookingBloc;
    if (bloc == null) {
      return Text(
        'Reviews',
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          color: context.colorScheme.onSurfaceVariant,
        ),
      );
    }
    return BlocBuilder<BookingBloc, BookingState>(
      bloc: bloc,
      builder: (context, state) {
        final feedback = _feedbackForState(state);
        final label = feedback.isLoading
            ? 'Reviews'
            : feedback.reviews.isEmpty
            ? '0 reviews'
            : feedback.reviews.length == 6
            ? '6+ reviews'
            : '${feedback.reviews.length} reviews';
        return Text(
          label,
          style: TextStyle(
            fontSize: 11.0,
            fontWeight: FontWeight.w600,
            color: context.colorScheme.onSurfaceVariant,
          ),
        );
      },
    );
  }

  Widget _buildRecentFeedbackList() {
    final bloc = _bookingBloc;
    if (bloc == null) {
      return Text(
        'No Passenger Feedback Yet.',
        style: TextStyle(
          fontSize: 12,
          color: context.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      );
    }
    return BlocBuilder<BookingBloc, BookingState>(
      bloc: bloc,
      builder: (context, state) {
        final feedback = _feedbackForState(state);
        return SizedBox(
          width: double.infinity,
          height: feedback.isLoading || feedback.reviews.isEmpty ? null : 190,
          child: feedback.isLoading
              ? const Skeletonizer.zone(
                  key: ValueKey('driver-feedback-loading-skeleton'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Bone.multiText(lines: 2, fontSize: 12),
                      SizedBox(height: 8),
                      Bone.multiText(lines: 2, fontSize: 12),
                    ],
                  ),
                )
              : feedback.reviews.isEmpty
              ? Text(
                  'No Passenger Feedback Yet.',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colorScheme.onSurface.withValues(
                      alpha: 0.65,
                    ),
                  ),
                )
              : ListView.separated(
                  primary: false,
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: feedback.reviews.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) =>
                      _buildReviewRow(feedback.reviews[index]),
                ),
        );
      },
    );
  }

  Widget _buildReviewRow(DriverReview review) {
    final passengerName = review.passengerName.trim();
    final comment = review.comment;
    final date = review.displayDate;
    final rating = review.rating;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  passengerName.isEmpty ? 'Passenger' : passengerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.colorScheme.onSurface,
                  ),
                ),
              ),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              ...List.generate(5, (index) {
                final filled = rating >= index + 1;
                return Icon(
                  filled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 12,
                  color: filled
                      ? context.semanticColors.warning
                      : context.colorScheme.onSurfaceVariant,
                );
              }),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '“$comment”',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              height: 1.25,
              color: context.colorScheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _dropdownAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width;
    final isCompactScreen = availableWidth <= 600.0;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440.0),
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: isCompactScreen ? 12.0 : 20.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(EasyRideRadius.sheet),
                border: Border.all(
                  color: context.colorScheme.outlineVariant,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 20.0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    layoutBuilder: (currentChild, _) => ClipRect(
                      child: currentChild ?? const SizedBox.shrink(),
                    ),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.12, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: widget.isProfileVisible
                        ? DriverProfileDetailsSheet(
                            key: ValueKey('driver-profile-${widget.driver.id}'),
                            driverId: widget.driver.id,
                            driverName: widget.driver.displayName,
                            vehicleType: widget.driver.vehicleType.isEmpty
                                ? 'Vehicle details unavailable'
                                : widget.driver.vehicleType,
                            plateNumber: widget.driver.plateNumber.isEmpty
                                ? '—'
                                : widget.driver.plateNumber,
                            rating: widget.driver.rating.toStringAsFixed(1),
                            onboardPassengerCount:
                                widget.driver.onboardPassengerCount,
                            embedded: true,
                            onBackPressed: widget.onProfileBackPressed,
                            repository: widget.profileRepository,
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 44.0,
                                    height: 44.0,
                                    decoration: BoxDecoration(
                                      color: context
                                          .colorScheme
                                          .secondaryContainer
                                          .withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: widget.isNearestDriver
                                            ? context.colorScheme.onSurface
                                            : context.colorScheme.surface
                                                  .withValues(alpha: 0),
                                        width: 2.0,
                                      ),
                                    ),
                                    child: Icon(
                                      LucideIcons.user,
                                      color: context.colorScheme.onSurface,
                                      size: 21.0,
                                    ),
                                  ),
                                  const SizedBox(width: 11.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                widget.driver.displayName,
                                                style: TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.w800,
                                                  color: context
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            if (widget.isNearestDriver) ...[
                                              const SizedBox(width: 6.0),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8.0,
                                                      vertical: 3.0,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: context
                                                      .colorScheme
                                                      .onSurface
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.0,
                                                      ),
                                                ),
                                                child: Text(
                                                  'Top Match',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                    color: context
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4.0),
                                        Row(
                                          children: [
                                            _DriverVehicleBadge(
                                              driver: widget.driver,
                                            ),
                                            const SizedBox(width: 8),
                                            _DriverLicensePlateBadge(
                                              plateNumber:
                                                  widget.driver.plateNumber,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: widget.onCloseDropdownPressed,
                                    icon: Icon(
                                      LucideIcons.x,
                                      size: 20.0,
                                      color: context.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                      vertical: 5.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: widget.driver.hasPassengerOnboard
                                          ? context.semanticColors.warning
                                                .withValues(alpha: 0.15)
                                          : context.semanticColors.success
                                                .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20.0),
                                      border: Border.all(
                                        color: widget.driver.hasPassengerOnboard
                                            ? context.semanticColors.warning
                                            : context.semanticColors.success,
                                        width: 1.0,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.driver.hasPassengerOnboard
                                              ? LucideIcons.users
                                              : LucideIcons.user_check,
                                          size: 14.0,
                                          color:
                                              widget.driver.hasPassengerOnboard
                                              ? context.semanticColors.warning
                                              : context.semanticColors.success,
                                        ),
                                        const SizedBox(width: 6.0),
                                        Text(
                                          widget.driver.hasPassengerOnboard
                                              ? 'Passenger Onboard'
                                              : 'Available',
                                          style: TextStyle(
                                            fontSize: 11.0,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                widget
                                                    .driver
                                                    .hasPassengerOnboard
                                                ? context.semanticColors.warning
                                                : context
                                                      .semanticColors
                                                      .success,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(
                                        EasyRideRadius.pill,
                                      ),
                                      border: Border.all(
                                        color:
                                            context.colorScheme.outlineVariant,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          LucideIcons.star,
                                          color: context.semanticColors.warning,
                                          size: 14.0,
                                        ),
                                        const SizedBox(width: 4.0),
                                        Text(
                                          widget.driver.rating.toStringAsFixed(
                                            1,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.w800,
                                            color:
                                                context.colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(width: 5.0),
                                        _buildReviewCountLabel(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10.0),
                              const SizedBox(height: 4),
                              Text(
                                'Recent Feedback',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: context.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildRecentFeedbackList(),
                              const SizedBox(height: 12.0),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: OutlinedButton(
                                  onPressed: widget.onViewFullProfilePressed,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        context.colorScheme.primary,
                                    side: BorderSide(
                                      color: context.colorScheme.outlineVariant,
                                      width: 1.2,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text(
                                    'View Full Profile',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: FilledButton(
                                  onPressed: widget.onSelectDriverPressed,
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        context.colorScheme.primary,
                                    foregroundColor:
                                        context.colorScheme.onPrimary,
                                    minimumSize: const Size(
                                      double.infinity,
                                      48,
                                    ),
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: const Text(
                                    'Book This Driver',
                                    style: TextStyle(
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class const _DriverVehicleBadge({required this.driver})
    extends StatelessWidget {
  final DriverModel driver;

  IconData get _icon {
    final vehicleType = driver.vehicleType.toLowerCase();
    if (vehicleType.contains('suv') || vehicleType.contains('sedan')) {
      return LucideIcons.car_front;
    }
    return LucideIcons.car;
  }

  @override
  Widget build(BuildContext context) {
    final label = driver.vehicleType.trim().isEmpty
        ? 'Vehicle'
        : driver.vehicleType.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(EasyRideRadius.pill),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: context.colorScheme.onSurface),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: context.colorScheme.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class const _DriverLicensePlateBadge({required this.plateNumber})
    extends StatelessWidget {
  final String plateNumber;

  @override
  Widget build(BuildContext context) {
    final label = plateNumber.trim().isEmpty ? '—' : plateNumber.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideRadius.pill),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: context.colorScheme.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
