import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/driver_profile/data/datasources/driver_profile_remote_data_source.dart';
import 'package:passenger_app/src/features/driver_profile/view/driver_profile_details_sheet.dart';
import 'package:shared_core/shared_core.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DriverDropdownCardWidget extends StatefulWidget {
  final DriverModel driver;
  final bool isNearestDriver;
  final bool isProfileVisible;
  final VoidCallback onViewFullProfilePressed;
  final VoidCallback onProfileBackPressed;
  final VoidCallback onSelectDriverPressed;
  final VoidCallback onCloseDropdownPressed;

  const DriverDropdownCardWidget({
    super.key,
    required this.driver,
    required this.isNearestDriver,
    this.isProfileVisible = false,
    required this.onViewFullProfilePressed,
    required this.onProfileBackPressed,
    required this.onSelectDriverPressed,
    required this.onCloseDropdownPressed,
  });

  @override
  State<DriverDropdownCardWidget> createState() =>
      _DriverDropdownCardWidgetState();
}

class _DriverDropdownCardWidgetState extends State<DriverDropdownCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dropdownAnimationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  List<Map<String, dynamic>> _recentReviews = const [];
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
    try {
      final rawReviews = await Modular.get<DriverProfileRemoteDataSource>()
          .fetchReviews(widget.driver.id, page: 1, limit: 6);
      final reviews = rawReviews
          .whereType<Map>()
          .map((review) {
            final comment = SafeParse.toStringValue(
              review['comment'] ?? review['feedback'] ?? review['message'],
            ).trim();
            return <String, dynamic>{
              'passengerName': SafeParse.toStringValue(
                review['passengerName'] ?? review['passenger_name'],
              ).trim(),
              'comment': comment,
              'rating': SafeParse.toNullableDouble(review['rating']) ?? 0,
              'date': _formatReviewDate(
                review['createdAt'] ?? review['created_at'],
              ),
            };
          })
          .where((review) => (review['comment'] as String).isNotEmpty)
          .take(6);
      if (!mounted) return;
      setState(() {
        _recentReviews =
            reviews.isEmpty &&
                widget.driver.recentFeedback?.trim().isNotEmpty == true
            ? [
                {
                  'passengerName': 'Passenger',
                  'comment': widget.driver.recentFeedback!.trim(),
                  'rating': widget.driver.rating,
                  'date': '',
                },
              ]
            : reviews.toList(growable: false);
        _isLoadingFeedback = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recentReviews = widget.driver.recentFeedback?.trim().isNotEmpty == true
            ? [
                {
                  'passengerName': 'Passenger',
                  'comment': widget.driver.recentFeedback!.trim(),
                  'rating': widget.driver.rating,
                  'date': '',
                },
              ]
            : const [];
        _isLoadingFeedback = false;
      });
    }
  }

  String _formatReviewDate(Object? value) {
    if (value == null) return '';
    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return '';
    const months = [
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
    return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
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
                color: AppTheme.primaryColor.withValues(alpha: 0.65),
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

  Widget _buildReviewRow(Map<String, dynamic> review) {
    final passengerName = (review['passengerName'] as String?)?.trim();
    final comment = review['comment'] as String? ?? '';
    final date = review['date'] as String? ?? '';
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  passengerName == null || passengerName.isEmpty
                      ? 'Passenger'
                      : passengerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              if (date.isNotEmpty)
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.primaryColor.withValues(alpha: 0.42),
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
                      ? AppTheme.warning
                      : AppTheme.primaryColor.withValues(alpha: 0.2),
                );
              }),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor.withValues(alpha: 0.58),
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
              color: AppTheme.primaryColor.withValues(alpha: 0.78),
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
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.14),
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
                                      color: AppTheme.secondaryColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: widget.isNearestDriver
                                            ? AppTheme.primaryColor
                                            : AppTheme.surface.withValues(
                                                alpha: 0,
                                              ),
                                        width: 2.0,
                                      ),
                                    ),
                                    child: const Icon(
                                      LucideIcons.user,
                                      color: AppTheme.primaryColor,
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
                                                style: const TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.w900,
                                                  color: AppTheme.primaryColor,
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
                                                  color: AppTheme.primaryColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        12.0,
                                                      ),
                                                ),
                                                child: const Text(
                                                  'Top Match',
                                                  style: TextStyle(
                                                    fontSize: 10.0,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppTheme.primaryColor,
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
                                            color: AppTheme.primaryColor
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: widget.onCloseDropdownPressed,
                                    icon: const Icon(
                                      LucideIcons.x,
                                      size: 20.0,
                                      color: AppTheme.primaryColor,
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
                                          ? AppTheme.warning.withValues(
                                              alpha: 0.15,
                                            )
                                          : AppTheme.complete.withValues(
                                              alpha: 0.15,
                                            ),
                                      borderRadius: BorderRadius.circular(20.0),
                                      border: Border.all(
                                        color: widget.driver.hasPassengerOnboard
                                            ? AppTheme.warning
                                            : AppTheme.complete,
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
                                              ? AppTheme.warning
                                              : AppTheme.complete,
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
                                                ? AppTheme.warning
                                                : AppTheme.complete,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        color: AppTheme.warning,
                                        size: 16.0,
                                      ),
                                      const SizedBox(width: 4.0),
                                      Text(
                                        widget.driver.rating.toStringAsFixed(1),
                                        style: const TextStyle(
                                          fontSize: 13.0,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        '${DistanceFormatter.fromKilometers(widget.driver.distanceKm)} away',
                                        style: TextStyle(
                                          fontSize: 12.0,
                                          color: AppTheme.primaryColor
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
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.6,
                                  ),
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
                                              AppTheme.primaryColor,
                                          side: const BorderSide(
                                            color: AppTheme.primaryColor,
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
                                              AppTheme.primaryColor,
                                          foregroundColor:
                                              AppTheme.activeControlForeground,
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
