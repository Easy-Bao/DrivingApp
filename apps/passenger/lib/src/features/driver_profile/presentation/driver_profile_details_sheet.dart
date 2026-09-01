import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const DriverProfileDetailsSheet({
  super.key,
  required this.driverId,
  required this.driverName,
  required this.vehicleType,
  required this.plateNumber,
  required this.rating,
  this.onboardPassengerCount,
  this.embedded = false,
  this.onBackPressed,
  required this.repository,
}) extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String vehicleType;
  final String plateNumber;
  final String rating;
  final int? onboardPassengerCount;
  final bool embedded;
  final VoidCallback? onBackPressed;
  final DriverProfileRepository repository;

  @override
  State<DriverProfileDetailsSheet> createState() =>
      _DriverProfileDetailsSheetState();
}

class _DriverProfileDetailsSheetState extends State<DriverProfileDetailsSheet> {
  static const _reviewPageSize = 3;
  late final ScrollController _scrollController;
  bool _isLoadingStats = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int? _completedTripsCount;
  List<DriverReview> _driverReviewsList = [];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    unawaited(_loadDriverProfileStats());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(_loadMoreDriverReviews());
    }
  }

  Future<void> _loadDriverProfileStats() async {
    _currentPage = 1;
    _hasMore = true;
    final statsFuture = widget.repository.fetchStats(widget.driverId);
    final reviewsFuture = widget.repository.fetchReviews(
      widget.driverId,
      page: _currentPage,
      limit: _reviewPageSize,
    );
    int? completedTrips;
    List<DriverReview> reviews = const [];
    (await statsFuture).fold(
      (_) {},
      (stats) => completedTrips = stats.completedTrips,
    );
    (await reviewsFuture).fold((_) => _hasMore = false, (value) {
      reviews = value;
      _hasMore = value.length >= _reviewPageSize;
    });

    if (mounted) {
      setState(() {
        _completedTripsCount = completedTrips;
        _driverReviewsList = reviews;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadMoreDriverReviews() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _currentPage + 1;
    List<DriverReview> nextReviews = const [];
    (await widget.repository.fetchReviews(
      widget.driverId,
      page: nextPage,
      limit: _reviewPageSize,
    )).fold((_) => _hasMore = false, (value) {
      nextReviews = value;
      _hasMore = value.length >= _reviewPageSize;
    });

    if (mounted) {
      setState(() {
        _currentPage = nextPage;
        _driverReviewsList.addAll(nextReviews);
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return SizedBox(height: 470, child: _buildProfileContent());
    }

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 550.0,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Container(
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: _buildProfileContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.embedded)
          Row(
            children: [
              IconButton(
                key: const ValueKey('driver-profile-back'),
                onPressed: widget.onBackPressed,
                style: IconButton.styleFrom(shape: const CircleBorder()),
                icon: Icon(
                  LucideIcons.arrow_left,
                  color: context.colorScheme.onSurface,
                ),
                tooltip: 'Back to driver summary',
              ),
              const SizedBox(width: 4),
              Text(
                'Driver profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          )
        else
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: context.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.colorScheme.secondaryContainer.withValues(
                  alpha: 0.2,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                LucideIcons.user,
                color: context.colorScheme.onSurface,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.driverName,
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.vehicleType} • ${widget.plateNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(height: 1, color: context.colorScheme.outlineVariant),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMetricCard(
              icon: LucideIcons.star,
              value: widget.rating,
              label: 'Rating',
              iconColor: context.semanticColors.warning,
            ),
            Container(
              width: 1,
              height: 40,
              color: context.colorScheme.outlineVariant,
            ),
            _buildMetricCard(
              icon: LucideIcons.bike,
              value: _isLoadingStats
                  ? '...'
                  : _completedTripsCount?.toString() ?? '—',
              label: 'Completed',
              iconColor: context.colorScheme.onSurface,
            ),
            Container(
              width: 1,
              height: 40,
              color: context.colorScheme.outlineVariant,
            ),
            _buildMetricCard(
              icon: LucideIcons.users,
              value: widget.onboardPassengerCount == null
                  ? '—'
                  : '${widget.onboardPassengerCount}/5',
              label: 'Onboard',
              iconColor: context.colorScheme.onSurface,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Passenger Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildReviews()),
      ],
    );
  }

  Widget _buildReviews() {
    if (_isLoadingStats) {
      return Skeletonizer.zone(
        child: ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _reviewPageSize,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, _) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colorScheme.outlineVariant),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(width: 140, fontSize: 14),
                SizedBox(height: 8),
                Bone.text(width: 110, fontSize: 12),
                SizedBox(height: 8),
                Bone.multiText(lines: 2, fontSize: 13),
              ],
            ),
          ),
        ),
      );
    }
    if (_driverReviewsList.isEmpty) {
      return Center(
        child: Text(
          'No passenger reviews yet.',
          style: TextStyle(
            color: context.colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      );
    }

    final showsLoader = _hasMore || _isLoadingMore;
    return ListView.builder(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _driverReviewsList.length + (showsLoader ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _driverReviewsList.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: context.colorScheme.onSurface,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }
        return _buildReviewCard(_driverReviewsList[index]);
      },
    );
  }

  Widget _buildReviewCard(DriverReview reviewItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reviewItem.passengerName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: context.colorScheme.onSurface,
                ),
              ),
              Text(
                reviewItem.displayDate,
                style: TextStyle(
                  fontSize: 11,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ...List.generate(5, (starIndex) {
                final ratingValue = reviewItem.rating;
                if (ratingValue >= starIndex + 1) {
                  return Icon(
                    Icons.star_rounded,
                    color: context.semanticColors.warning,
                    size: 13,
                  );
                } else if (ratingValue >= starIndex + 0.5) {
                  return Icon(
                    Icons.star_half_rounded,
                    color: context.semanticColors.warning,
                    size: 13,
                  );
                }
                return Icon(
                  Icons.star_rounded,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.12),
                  size: 13,
                );
              }),
              const SizedBox(width: 6),
              Text(
                reviewItem.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reviewItem.comment,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: context.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: context.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
