import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/driver_profile/domain/entities/driver_review.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DriverProfileDetailsSheet extends StatefulWidget {
  const DriverProfileDetailsSheet({
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
  });
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
  String? _nextCursor;
  int? _completedTripsCount;
  String? _reviewsErrorMessage;
  String? _loadMoreErrorMessage;
  List<DriverReview> _driverReviewsList = <DriverReview>[];

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
    if (!_scrollController.hasClients || _loadMoreErrorMessage != null) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(_loadMoreDriverReviews());
    }
  }

  Future<void> _loadDriverProfileStats() async {
    _currentPage = 1;
    _nextCursor = null;
    _hasMore = true;
    if (mounted && !_isLoadingStats) {
      setState(() {
        _isLoadingStats = true;
        _reviewsErrorMessage = null;
        _loadMoreErrorMessage = null;
      });
    }
    final statsFuture = widget.repository.fetchStatsResult(widget.driverId);
    final reviewsFuture = widget.repository.fetchReviewsResult(
      widget.driverId,
      page: _currentPage,
      limit: _reviewPageSize,
    );
    int? completedTrips;
    var reviews = <DriverReview>[];
    String? reviewsErrorMessage;
    (await statsFuture).fold(
      (_) {},
      (stats) => completedTrips = stats.completedTrips,
    );
    (await reviewsFuture).fold(
      (failure) {
        _hasMore = false;
        reviewsErrorMessage = failure.message;
      },
      (value) {
        reviews = List<DriverReview>.of(value.items);
        _hasMore = value.hasMore;
        _nextCursor = value.nextCursor;
      },
    );

    if (mounted) {
      setState(() {
        _completedTripsCount = completedTrips;
        _driverReviewsList = reviews;
        _reviewsErrorMessage = reviewsErrorMessage;
        _loadMoreErrorMessage = null;
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _loadMoreDriverReviews() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
      _loadMoreErrorMessage = null;
    });

    final nextPage = _currentPage + 1;
    var nextReviews = const <DriverReview>[];
    String? loadMoreError;
    (await widget.repository.fetchReviewsResult(
      widget.driverId,
      page: nextPage,
      cursor: _nextCursor,
      limit: _reviewPageSize,
    )).fold((failure) => loadMoreError = failure.message, (value) {
      nextReviews = value.items;
      _hasMore = value.hasMore;
      _nextCursor = value.nextCursor;
    });

    if (mounted) {
      setState(() {
        if (loadMoreError == null) {
          _currentPage = nextPage;
          _driverReviewsList = <DriverReview>[
            ..._driverReviewsList,
            ...nextReviews,
          ];
        }
        _loadMoreErrorMessage = loadMoreError;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 470),
        child: _buildProfileContent(),
      );
    }

    final sheetHeight = MediaQuery.sizeOf(context).height * 0.74;
    return AppBottomSheetContainer(
      showShadow: true,
      maxWidth: 550.0,
      padding: const EdgeInsets.fromLTRB(
        AppLayout.pagePadding,
        AppSpacing.sm + 2,
        AppLayout.pagePadding,
        AppLayout.pagePadding,
      ),
      child: SizedBox(height: sheetHeight, child: _buildProfileContent()),
    );
  }

  Widget _buildProfileContent() {
    final colors = context.colorScheme;
    final hairline = colors.outlineVariant.withValues(alpha: 0.7);
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
                style:
                    IconButton.styleFrom(
                      foregroundColor: colors.onSurface,
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
                icon: const Icon(LucideIcons.arrow_left, size: 19),
                tooltip: 'Back to driver summary',
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Driver profile',
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
            ],
          ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.surfaceContainerLowest,
                shape: BoxShape.circle,
                border: Border.all(color: colors.outlineVariant),
              ),
              alignment: Alignment.center,
              child: Icon(LucideIcons.user, color: colors.onSurface, size: 22),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.driverName,
                    style: context.textStyles.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.vehicleType} • ${widget.plateNumber}',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Divider(height: 1, color: hairline),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMetricCard(
              icon: Icons.star_rounded,
              value: widget.rating,
              label: 'Rating',
              iconColor: context.semanticColors.rating,
            ),
            Container(width: 1, height: 36, color: hairline),
            _buildMetricCard(
              icon: LucideIcons.bike,
              value: _isLoadingStats
                  ? '...'
                  : _completedTripsCount?.toString() ?? '—',
              label: 'Completed',
              iconColor: colors.onSurface,
            ),
            Container(width: 1, height: 36, color: hairline),
            _buildMetricCard(
              icon: LucideIcons.users,
              value: widget.onboardPassengerCount == null
                  ? '—'
                  : '${widget.onboardPassengerCount}/5',
              label: 'Onboard',
              iconColor: colors.onSurface,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Divider(height: 1, color: hairline),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Passenger Reviews',
          style: context.textStyles.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(child: _buildReviews()),
      ],
    );
  }

  Widget _buildReviews() {
    final colors = context.colorScheme;
    final hairline = colors.outlineVariant.withValues(alpha: 0.7);
    if (_isLoadingStats) {
      return Skeletonizer.zone(
        key: const ValueKey<String>('driver-profile-reviews-loading-skeleton'),
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: 3,
          separatorBuilder: (_, _) => Divider(height: 1, color: hairline),
          itemBuilder: (_, _) => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Bone.text(width: 110, fontSize: 14)),
                    Bone.text(width: 42, fontSize: 11),
                  ],
                ),
                SizedBox(height: 6),
                Bone.text(width: 96, fontSize: 12),
                SizedBox(height: 6),
                Bone.multiText(lines: 2, fontSize: 12),
              ],
            ),
          ),
        ),
      );
    }
    if (_driverReviewsList.isEmpty) {
      if (_reviewsErrorMessage case final errorMessage?) {
        return AppRetryErrorView(
          title: 'Could not load reviews',
          message: errorMessage,
          onRetry: () => unawaited(_loadDriverProfileStats()),
        );
      }
      return Center(
        child: Text(
          'No passenger reviews yet.',
          style: context.textStyles.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
      );
    }

    final showsFooter =
        _hasMore || _isLoadingMore || _loadMoreErrorMessage != null;
    return ListView.separated(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: _driverReviewsList.length + (showsFooter ? 1 : 0),
      separatorBuilder: (_, _) => Divider(height: 1, color: hairline),
      itemBuilder: (context, index) {
        if (index == _driverReviewsList.length) {
          if (_loadMoreErrorMessage case final loadMoreError?) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      loadMoreError,
                      style: context.textStyles.bodySmall?.copyWith(
                        color: colors.error,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => unawaited(_loadMoreDriverReviews()),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.onSurface,
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                    ),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: colors.onSurface,
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
    final colors = context.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  reviewItem.passengerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                reviewItem.displayDate,
                style: context.textStyles.labelSmall?.tabular.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              ...List.generate(5, (starIndex) {
                final ratingValue = reviewItem.rating;
                if (ratingValue >= starIndex + 1) {
                  return Icon(
                    Icons.star_rounded,
                    color: context.semanticColors.rating,
                    size: 14,
                  );
                } else if (ratingValue >= starIndex + 0.5) {
                  return Icon(
                    Icons.star_half_rounded,
                    color: context.semanticColors.rating,
                    size: 14,
                  );
                }
                return Icon(
                  Icons.star_rounded,
                  color: colors.outlineVariant,
                  size: 14,
                );
              }),
              const SizedBox(width: 6),
              Text(
                reviewItem.rating.toStringAsFixed(1),
                style: context.textStyles.labelSmall?.tabular.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            reviewItem.comment,
            style: context.textStyles.bodySmall?.copyWith(
              height: 1.45,
              color: colors.onSurfaceVariant,
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
    final colors = context.colorScheme;
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 19),
        const SizedBox(height: 6),
        Text(
          value,
          style: context.textStyles.titleMedium?.tabular.copyWith(
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: context.textStyles.labelSmall?.copyWith(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
