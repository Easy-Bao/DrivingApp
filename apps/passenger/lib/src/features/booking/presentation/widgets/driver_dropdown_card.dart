import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/presentation/bloc/booking/booking_bloc.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/driver_profile/presentation/widgets/driver_profile_details_sheet.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DriverDropdownCard extends StatefulWidget {
  final Driver driver;
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
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: context.colorScheme.outlineVariant.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  itemBuilder: (_, index) =>
                      _buildReviewRow(feedback.reviews[index]),
                ),
        );
      },
    );
  }

  Widget _buildReviewRow(DriverReview review) {
    final colors = context.colorScheme;
    final passengerName = review.passengerName.trim();
    final comment = review.comment;
    final date = review.displayDate;
    final rating = review.rating;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                  style: context.textStyles.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: context.textStyles.labelSmall?.tabular.copyWith(
                    color: colors.onSurfaceVariant,
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
                      ? context.semanticColors.rating
                      : colors.outlineVariant,
                );
              }),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: context.textStyles.labelSmall?.tabular.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            '“$comment”',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.bodySmall?.copyWith(
              height: 1.35,
              color: colors.onSurfaceVariant,
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
    final colors = context.colorScheme;
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
                color: colors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppRadius.sheet),
                border: Border.all(color: colors.outlineVariant),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.06),
                    blurRadius: 16.0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: AnimatedSize(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
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
                                      color: colors.surfaceContainerLowest,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: widget.isNearestDriver
                                            ? colors.onSurface
                                            : colors.outlineVariant,
                                        width: widget.isNearestDriver
                                            ? 1.5
                                            : 1.0,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      LucideIcons.user,
                                      color: colors.onSurface,
                                      size: 20.0,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
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
                                                style: context
                                                    .textStyles
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: colors.onSurface,
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
                                                      vertical: 2.0,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: colors
                                                      .surfaceContainerLowest,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppRadius.pill,
                                                      ),
                                                  border: Border.all(
                                                    color:
                                                        colors.outlineVariant,
                                                  ),
                                                ),
                                                child: Text(
                                                  'Top Match',
                                                  style: context
                                                      .textStyles
                                                      .labelSmall
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: colors.onSurface,
                                                      ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 6.0),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            _DriverVehicleBadge(
                                              driver: widget.driver,
                                            ),
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
                                    style:
                                        IconButton.styleFrom(
                                          foregroundColor:
                                              colors.onSurfaceVariant,
                                          enableFeedback: false,
                                          splashFactory: NoSplash.splashFactory,
                                        ).copyWith(
                                          overlayColor:
                                              WidgetStateProperty.resolveWith(
                                                (states) =>
                                                    states.contains(
                                                      WidgetState.focused,
                                                    )
                                                    ? colors.primary.withValues(
                                                        alpha: 0.12,
                                                      )
                                                    : Colors.transparent,
                                              ),
                                        ),
                                    icon: const Icon(LucideIcons.x, size: 19.0),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0,
                                      vertical: 5.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                      border: Border.all(
                                        color: widget.driver.hasPassengerOnboard
                                            ? context.semanticColors.warning
                                                  .withValues(alpha: 0.5)
                                            : context.semanticColors.success
                                                  .withValues(alpha: 0.45),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.driver.hasPassengerOnboard
                                              ? LucideIcons.users
                                              : LucideIcons.user_check,
                                          size: 13.0,
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
                                          style: context.textStyles.labelSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    widget
                                                        .driver
                                                        .hasPassengerOnboard
                                                    ? context
                                                          .semanticColors
                                                          .warning
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
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainerLowest,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                      border: Border.all(
                                        color: colors.outlineVariant,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          color: context.semanticColors.rating,
                                          size: 14.0,
                                        ),
                                        const SizedBox(width: 4.0),
                                        Text(
                                          widget.driver.rating.toStringAsFixed(
                                            1,
                                          ),
                                          style: context
                                              .textStyles
                                              .labelSmall
                                              ?.tabular
                                              .copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: colors.onSurface,
                                              ),
                                        ),
                                        const SizedBox(width: 5.0),
                                        _buildReviewCountLabel(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md,
                                ),
                                child: Divider(
                                  height: 1,
                                  color: colors.outlineVariant.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              Text(
                                'Recent Feedback',
                                style: context.textStyles.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 6),
                              _buildRecentFeedbackList(),
                              const SizedBox(height: AppSpacing.md),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: widget.onViewFullProfilePressed,
                                  style:
                                      OutlinedButton.styleFrom(
                                        backgroundColor:
                                            colors.surfaceContainerLowest,
                                        foregroundColor: colors.onSurface,
                                        side: BorderSide(
                                          color: colors.outlineVariant,
                                        ),
                                        enableFeedback: false,
                                        splashFactory: NoSplash.splashFactory,
                                        minimumSize: const Size.fromHeight(
                                          AppSize.minimumTouchTarget,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.lg,
                                          ),
                                        ),
                                        textStyle: context.textStyles.labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ).copyWith(
                                        overlayColor:
                                            WidgetStateProperty.resolveWith(
                                              (states) =>
                                                  states.contains(
                                                    WidgetState.focused,
                                                  )
                                                  ? colors.primary.withValues(
                                                      alpha: 0.12,
                                                    )
                                                  : Colors.transparent,
                                            ),
                                      ),
                                  child: const Text('View Full Profile'),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: widget.onSelectDriverPressed,
                                  style:
                                      FilledButton.styleFrom(
                                        backgroundColor: colors.primary,
                                        foregroundColor: colors.onPrimary,
                                        elevation: 0,
                                        enableFeedback: false,
                                        splashFactory: NoSplash.splashFactory,
                                        minimumSize: const Size.fromHeight(
                                          AppSize.minimumTouchTarget,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            AppRadius.lg,
                                          ),
                                        ),
                                        textStyle: context.textStyles.labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ).copyWith(
                                        overlayColor:
                                            WidgetStateProperty.resolveWith(
                                              (states) =>
                                                  states.contains(
                                                    WidgetState.focused,
                                                  )
                                                  ? colors.onPrimary.withValues(
                                                      alpha: 0.16,
                                                    )
                                                  : Colors.transparent,
                                            ),
                                      ),
                                  child: const Text('Book This Driver'),
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
  final Driver driver;

  IconData get _icon {
    final vehicleType = driver.vehicleType.toLowerCase();
    if (vehicleType.contains('suv') || vehicleType.contains('sedan')) {
      return LucideIcons.car_front;
    }
    return LucideIcons.car;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
    final label = driver.vehicleType.trim().isEmpty
        ? 'Vehicle'
        : driver.vehicleType.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 13, color: colors.onSurfaceVariant),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textStyles.labelSmall?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
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
    final colors = context.colorScheme;
    final label = plateNumber.trim().isEmpty ? '—' : plateNumber.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.textStyles.labelSmall?.tabular.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
