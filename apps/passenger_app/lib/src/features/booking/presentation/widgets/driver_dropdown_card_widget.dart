import 'package:passenger_app/src/features/booking/booking.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger_app/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger_app/src/features/driver_profile/presentation/driver_profile_details_sheet.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const DriverDropdownCardWidget({
  super.key,
  required this.driver,
  required this.isNearestDriver,
  this.isProfileVisible = false,
  required this.onViewFullProfilePressed,
  required this.onProfileBackPressed,
  required this.onSelectDriverPressed,
  required this.onCloseDropdownPressed,
  required this.profileRepository,
}) extends StatefulWidget {
  final DriverModel driver;
  final bool isNearestDriver;
  final bool isProfileVisible;
  final VoidCallback onViewFullProfilePressed;
  final VoidCallback onProfileBackPressed;
  final VoidCallback onSelectDriverPressed;
  final VoidCallback onCloseDropdownPressed;
  final DriverProfileRepository profileRepository;

  @override
  State<DriverDropdownCardWidget> createState() =>
      _DriverDropdownCardWidgetState();
}

class _DriverDropdownCardWidgetState()
    extends State<DriverDropdownCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dropdownAnimationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  List<DriverReview> _recentReviews = const [];
  bool _isLoadingFeedback = true;

  @override
  void initState() {
    super.initState();
    _dropdownAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _dropdownAnimationController,
            curve: Curves.easeOutBack,
          ),
        );

    _fadeAnimation = CurvedAnimation(
      parent: _dropdownAnimationController,
      curve: Curves.easeIn,
    );

    unawaited(_dropdownAnimationController.forward());
    unawaited(_loadRecentFeedback());
  }

  Future<void> _loadRecentFeedback() async {
    List<DriverReview> reviews = const [];
    (await widget.profileRepository.fetchReviews(
      widget.driver.id,
      page: 1,
      limit: 6,
    )).fold((_) {}, (value) => reviews = value);
    if (!mounted) return;
    final visibleReviews = reviews
        .where((review) => review.comment.isNotEmpty)
        .take(6)
        .toList(growable: false);
    setState(() {
      _recentReviews =
          visibleReviews.isEmpty &&
              widget.driver.recentFeedback?.trim().isNotEmpty == true
          ? [
              DriverReview(
                passengerName: 'Passenger',
                comment: widget.driver.recentFeedback!.trim(),
                rating: widget.driver.rating,
              ),
            ]
          : visibleReviews;
      _isLoadingFeedback = false;
    });
  }

  Widget _buildRecentFeedbackList() {
    return SizedBox(
      width: double.infinity,
      height: _isLoadingFeedback || _recentReviews.isEmpty ? null : 190,
      child: _isLoadingFeedback
          ? const Skeletonizer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(words: 5),
                  SizedBox(height: 7),
                  Bone.text(words: 4),
                  SizedBox(height: 7),
                  Bone.text(words: 6),
                ],
              ),
            )
          : _recentReviews.isEmpty
          ? Text(
              'No Passenger Feedback Yet.',
              style: TextStyle(
                fontSize: 12,
                color: context.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            )
          : ListView.separated(
              primary: false,
              padding: EdgeInsets.zero,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _recentReviews.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, index) => _buildReviewRow(_recentReviews[index]),
            ),
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
        borderRadius: BorderRadius.circular(16),
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
                      : context.colorScheme.onSurface.withValues(alpha: 0.2),
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
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colorScheme.onSurface.withValues(
                      alpha: 0.14,
                    ),
                    blurRadius: 24.0,
                    offset: const Offset(0, 8),
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
                                        Text(
                                          widget.driver.vehicleSummary,
                                          style: TextStyle(
                                            fontSize: 11.0,
                                            fontWeight: FontWeight.w600,
                                            color: context.colorScheme.onSurface
                                                .withValues(alpha: 0.6),
                                          ),
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
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: context.semanticColors.warning,
                                        size: 16.0,
                                      ),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        widget.driver.rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.bold,
                                          color: context.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        '${DistanceFormatter.fromKilometers(widget.driver.distanceKm)} away',
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          color: context.colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
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
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 44.0,
                                      child: OutlinedButton(
                                        onPressed:
                                            widget.onViewFullProfilePressed,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              context.colorScheme.onSurface,
                                          side: BorderSide(
                                            color:
                                                context.colorScheme.onSurface,
                                            width: 1.5,
                                          ),
                                          padding: EdgeInsets.zero,
                                          shape: const StadiumBorder(),
                                        ),
                                        child: const Text(
                                          'View Full Profile',
                                          style: TextStyle(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: SizedBox(
                                      height: 44.0,
                                      child: ElevatedButton(
                                        onPressed: widget.onSelectDriverPressed,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              context.colorScheme.onSurface,
                                          foregroundColor:
                                              context.colorScheme.onPrimary,
                                          elevation: 0,
                                          padding: EdgeInsets.zero,
                                          shape: const StadiumBorder(),
                                        ),
                                        child: const Text(
                                          'Select Driver',
                                          style: TextStyle(
                                            fontSize: 13.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
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
