import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/services/secure_session_service.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/activity/activity_routes.dart';
import 'package:passenger_app/src/features/activity/domain/repositories/i_activity_repository.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

class PassengerViewAllActivityPage extends StatefulWidget {
  const PassengerViewAllActivityPage({super.key});

  @override
  State<PassengerViewAllActivityPage> createState() =>
      _PassengerViewAllActivityPageState();
}

class _PassengerViewAllActivityPageState
    extends State<PassengerViewAllActivityPage> {
  static const int _activitySkeletonLimit = 8;

  static const _monthAbbreviationsList = [
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
  List<RideHistoryModel> _retrievedRidesList = [];
  bool _isActivityDataLoading = true;
  String _selectedStatusFilter = 'ALL';

  String _networkErrorMessage = '';

  List<RideHistoryModel> get _filteredRidesList {
    if (_selectedStatusFilter == 'ALL') {
      return _retrievedRidesList;
    }
    return _retrievedRidesList.where((rideRecord) {
      return rideRecord.status.toUpperCase() == _selectedStatusFilter;
    }).toList();
  }

  Map<String, List<RideHistoryModel>> get _groupedActivityRides {
    final Map<String, List<RideHistoryModel>> groupedMap = {};
    for (final ride in _filteredRidesList) {
      final groupingDateKey = _getGroupingDateKey(ride);
      if (!groupedMap.containsKey(groupingDateKey)) {
        groupedMap[groupingDateKey] = [];
      }
      groupedMap[groupingDateKey]!.add(ride);
    }
    return groupedMap;
  }

  void _displayTripHistoryFilterModalBottomSheet(BuildContext context) {
    unawaited(_selectTripHistoryFilter(context));
  }

  Future<void> _selectTripHistoryFilter(BuildContext context) async {
    final selectedFilter = switch (_selectedStatusFilter) {
      'COMPLETED' => TripHistoryFilter.completed,
      'CANCELLED' => TripHistoryFilter.cancelled,
      _ => TripHistoryFilter.all,
    };
    final result = await showTripHistoryFilterSheet(
      context: context,
      selectedFilter: selectedFilter,
    );
    if (!mounted || result == null) return;
    setState(() {
      _selectedStatusFilter = switch (result) {
        TripHistoryFilter.all => 'ALL',
        TripHistoryFilter.completed => 'COMPLETED',
        TripHistoryFilter.cancelled => 'CANCELLED',
      };
    });
  }

  Widget _buildLoadingState({required int itemCount}) {
    return Skeletonizer.zone(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (index.isEven) ...[
                  const Bone.text(width: 86, fontSize: 13),
                  const SizedBox(height: 8),
                ],
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.borderSide.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Bone.circle(size: 40),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Bone.text(width: 140, fontSize: 15),
                            SizedBox(height: 8),
                            Bone.text(width: 190, fontSize: 13),
                          ],
                        ),
                      ),
                      SizedBox(width: 12),
                      Bone.text(width: 52, fontSize: 11),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: IconButton(
            onPressed: () => context.pop(),
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(shape: const CircleBorder()),
            icon: const Icon(
              LucideIcons.arrow_left,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
        ),
        title: const Text(
          'Trip history',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.funnel, color: AppTheme.primaryColor),
            onPressed: () {
              _displayTripHistoryFilterModalBottomSheet(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isActivityDataLoading && _retrievedRidesList.isNotEmpty
          ? _buildLoadingState(
              itemCount: _retrievedRidesList.length
                  .clamp(1, _activitySkeletonLimit)
                  .toInt(),
            )
          : _networkErrorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _networkErrorMessage,
                  style: const TextStyle(
                    color: AppTheme.cancel,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _filteredRidesList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 48,
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No activity yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              physics: const BouncingScrollPhysics(),
              itemCount: _groupedActivityRides.keys.length,
              itemBuilder: (context, sectionIndex) {
                final groupingDateKey = _groupedActivityRides.keys.elementAt(
                  sectionIndex,
                );
                final groupedRideItems =
                    _groupedActivityRides[groupingDateKey]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      child: Text(
                        groupingDateKey,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...groupedRideItems.map(
                      (rideItem) => _buildActivityCard(rideItem),
                    ),
                  ],
                );
              },
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    unawaited(_fetchActivityHistoryData());
  }

  Widget _buildActivityCard(RideHistoryModel ride) {
    final isTripCompleted = ride.status.toLowerCase() == 'completed';
    final dateStringParts = ride.date.split(',');
    final formattedActivityTime = dateStringParts.length > 1
        ? dateStringParts[1].trim()
        : '';
    final totalTripPrice = _priceValue(ride.price);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Material(
        color: AppTheme.surface.withValues(alpha: 0),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (isTripCompleted) {
              unawaited(
                context.pushNamed(
                  ActivityRoutes.activityViewDetails,
                  extra: ride,
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      formattedActivityTime,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isTripCompleted
                            ? AppTheme.complete.withValues(alpha: 0.1)
                            : AppTheme.cancel.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isTripCompleted ? 'Completed' : 'Cancelled',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isTripCompleted
                              ? AppTheme.complete
                              : AppTheme.cancel,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                CompactRouteTimelineWidget(
                  pickup: ride.pickup,
                  dropoff: ride.destination,
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, color: AppTheme.borderSide),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _tripMeta(
                        'Ride Type',
                        ride.vehicleType.toLowerCase().contains('share')
                            ? 'Shared Ride'
                            : 'Solo Ride',
                      ),
                    ),
                    Container(width: 1, height: 28, color: AppTheme.borderSide),
                    Expanded(
                      child: _tripMeta(
                        'Fare',
                        '₱${totalTripPrice.toStringAsFixed(2)}',
                      ),
                    ),
                  ],
                ),
                if (!isTripCompleted) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Trip cancelled before reaching the destination.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tripMeta(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor.withValues(alpha: 0.42),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  double _priceValue(String price) {
    final normalized = price.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(normalized) ?? 0.0;
  }

  Future<void> _fetchActivityHistoryData() async {
    setState(() {
      _isActivityDataLoading = true;
      _networkErrorMessage = '';
    });
    try {
      final storedPassengerId =
          await Modular.get<SecureSessionService>().readPassengerId() ?? '';
      if (storedPassengerId.isNotEmpty) {
        final activityRepositoryInstance = Modular.get<IActivityRepository>();
        final retrievedRidesHistoryResult = await activityRepositoryInstance
            .fetchRideHistory(storedPassengerId);
        if (mounted) {
          retrievedRidesHistoryResult.fold(
            (failure) {
              setState(() {
                _retrievedRidesList = const [];
                _networkErrorMessage = ErrorHandler.getErrorMessage(failure);
                _isActivityDataLoading = false;
              });
            },
            (ridesList) {
              setState(() {
                _retrievedRidesList = ridesList;
                _isActivityDataLoading = false;
              });
            },
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _retrievedRidesList = const [];
            _isActivityDataLoading = false;
          });
        }
      }
    } catch (exceptionError) {
      if (mounted) {
        setState(() {
          _networkErrorMessage = ErrorHandler.getErrorMessage(exceptionError);
          _isActivityDataLoading = false;
        });
      }
    }
  }

  String _getGroupingDateKey(RideHistoryModel ride) {
    final dateStringParts = ride.date.split(',');
    if (dateStringParts.isEmpty) return 'Unknown';
    final extractedDatePart = dateStringParts[0].trim();

    try {
      final currentDateTime = DateTime.now();
      final todayDateString =
          '${_monthAbbreviationsList[currentDateTime.month - 1]} ${currentDateTime.day}';
      final yesterdayDateTime = currentDateTime.subtract(
        const Duration(days: 1),
      );
      final yesterdayDateString =
          '${_monthAbbreviationsList[yesterdayDateTime.month - 1]} ${yesterdayDateTime.day}';

      if (extractedDatePart.toUpperCase() == todayDateString.toUpperCase()) {
        return 'Today';
      } else if (extractedDatePart.toUpperCase() ==
          yesterdayDateString.toUpperCase()) {
        return 'Yesterday';
      }
    } catch (_) {}

    if (extractedDatePart.length >= 3) {
      final extractedMonthString = extractedDatePart
          .substring(0, 3)
          .toLowerCase();
      final capitalizedMonthString =
          extractedMonthString[0].toUpperCase() +
          extractedMonthString.substring(1);
      final remainingDateString = extractedDatePart.substring(3);
      return '$capitalizedMonthString$remainingDateString';
    }

    return extractedDatePart;
  }
}
