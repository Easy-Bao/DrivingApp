import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';

class DriverProfileDetailsSheet extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String vehicleType;
  final String plateNumber;
  final String rating;
  final int? onboardPassengerCount;
  final bool embedded;
  final VoidCallback? onBackPressed;

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
  });

  @override
  State<DriverProfileDetailsSheet> createState() =>
      _DriverProfileDetailsSheetState();
}

class _DriverProfileDetailsSheetState extends State<DriverProfileDetailsSheet> {
  late final ScrollController _scrollController;
  bool _isLoadingStats = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int? _completedTripsCount;
  List<Map<String, dynamic>> _driverReviewsList = [];

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
    try {
      final statsData = await Modular.get<BiddingRemoteDataSource>()
          .fetchDriverStats(widget.driverId);
      final completedTrips =
          statsData['completedTrips'] ?? statsData['completed_trips'];
      if (completedTrips is num) {
        if (mounted) {
          setState(() {
            _completedTripsCount = completedTrips.toInt();
          });
        }
      }
    } catch (error) {
      dev.log('Unable to load driver stats: $error');
    }

    _currentPage = 1;
    _hasMore = true;
    final List<Map<String, dynamic>> dynamicReviews = [];
    try {
      final rawReviews = await Modular.get<BiddingRemoteDataSource>()
          .fetchDriverReviews(widget.driverId, page: _currentPage, limit: 5);
      if (rawReviews.length < 5) {
        _hasMore = false;
      }
      for (final r in rawReviews) {
        if (r is Map<String, dynamic>) {
          final review = _parseReview(r);
          if (review['rating'] is num) dynamicReviews.add(review);
        }
      }
    } catch (error) {
      dev.log('Unable to load driver reviews: $error');
      _hasMore = false;
    }

    if (mounted) {
      setState(() {
        _driverReviewsList = dynamicReviews;
        _isLoadingStats = false;
      });
    }
  }

  Map<String, dynamic> _parseReview(Map<String, dynamic> r) {
    final createdAtStr = r['createdAt'] ?? r['created_at'];
    var dateFormatted = '';
    if (createdAtStr != null) {
      try {
        final parsedDate = DateTime.parse(createdAtStr.toString());
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        dateFormatted =
            '${months[parsedDate.month - 1]} ${parsedDate.day}, ${parsedDate.year}';
      } catch (error) {
        dev.log('Unable to parse review date: $error');
      }
    }

    return {
      'passengerName': r['passengerName'] ?? r['passenger_name'],
      'comment': r['comment'],
      'rating': (r['rating'] as num?)?.toDouble(),
      'date': dateFormatted,
    };
  }

  Future<void> _loadMoreDriverReviews() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _currentPage + 1;
    final List<Map<String, dynamic>> nextReviews = [];
    try {
      final rawReviews = await Modular.get<BiddingRemoteDataSource>()
          .fetchDriverReviews(widget.driverId, page: nextPage, limit: 5);
      if (rawReviews.length < 5) {
        _hasMore = false;
      }
      for (final r in rawReviews) {
        if (r is Map<String, dynamic>) {
          final review = _parseReview(r);
          if (review['rating'] is num) nextReviews.add(review);
        }
      }
    } catch (_) {
      _hasMore = false;
    }

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
              color: AppTheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
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
                icon: const Icon(
                  LucideIcons.arrow_left,
                  color: AppTheme.primaryColor,
                ),
                tooltip: 'Back to driver summary',
              ),
              const SizedBox(width: 4),
              const Text(
                'Driver profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
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
                color: AppTheme.borderSide,
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
                color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                LucideIcons.user,
                color: AppTheme.primaryColor,
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
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.vehicleType} • ${widget.plateNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(height: 1, color: AppTheme.borderSide),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMetricCard(
              icon: LucideIcons.star,
              value: widget.rating,
              label: 'Rating',
              iconColor: Colors.amber,
            ),
            Container(width: 1, height: 40, color: AppTheme.borderSide),
            _buildMetricCard(
              icon: LucideIcons.bike,
              value: _isLoadingStats
                  ? '...'
                  : _completedTripsCount?.toString() ?? '—',
              label: 'Completed',
              iconColor: AppTheme.primaryColor,
            ),
            Container(width: 1, height: 40, color: AppTheme.borderSide),
            _buildMetricCard(
              icon: LucideIcons.users,
              value: widget.onboardPassengerCount == null
                  ? '—'
                  : '${widget.onboardPassengerCount}/5',
              label: 'Onboard',
              iconColor: AppTheme.primaryColor,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Passenger Reviews',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: _buildReviews()),
      ],
    );
  }

  Widget _buildReviews() {
    if (_isLoadingStats) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }
    if (_driverReviewsList.isEmpty) {
      return Center(
        child: Text(
          'No passenger reviews yet.',
          style: TextStyle(
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
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

  Widget _buildReviewCard(Map<String, dynamic> reviewItem) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                reviewItem['passengerName']?.toString() ?? '—',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                reviewItem['date']?.toString() ?? '—',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              ...List.generate(5, (starIndex) {
                final ratingValue =
                    (reviewItem['rating'] as num?)?.toDouble() ?? 0.0;
                if (ratingValue >= starIndex + 1) {
                  return const Icon(
                    Icons.star_rounded,
                    color: Colors.amber,
                    size: 13,
                  );
                } else if (ratingValue >= starIndex + 0.5) {
                  return const Icon(
                    Icons.star_half_rounded,
                    color: Colors.amber,
                    size: 13,
                  );
                }
                return Icon(
                  Icons.star_rounded,
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  size: 13,
                );
              }),
              const SizedBox(width: 6),
              Text(
                ((reviewItem['rating'] as num?)?.toDouble() ?? 0.0)
                    .toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reviewItem['comment']?.toString() ?? '',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppTheme.primaryColor.withValues(alpha: 0.7),
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
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
