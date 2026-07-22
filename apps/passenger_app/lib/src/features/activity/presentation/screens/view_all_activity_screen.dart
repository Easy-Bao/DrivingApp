import 'dart:async';
import 'dart:math';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/activity/activity_routes.dart';
import 'package:passenger_app/src/features/activity/domain/repositories/activity_repository.dart';
import 'package:session_service/session_service.dart';
import 'package:shared_ui/shared_ui.dart';

class PassengerViewAllActivityScreen extends StatefulWidget {
  const PassengerViewAllActivityScreen({super.key});

  @override
  State<PassengerViewAllActivityScreen> createState() =>
      _PassengerViewAllActivityScreenState();
}

class _PassengerViewAllActivityScreenState extends State<PassengerViewAllActivityScreen> {
  static const _monthAbbreviationsList = [
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
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
    unawaited(
      showModalBottomSheet<void>(
        context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext modalContext) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Trip History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('All Trips'),
                leading: Icon(
                  LucideIcons.list,
                  color: _selectedStatusFilter == 'ALL'
                      ? AppTheme.primaryColor
                      : AppTheme.tertiaryColor,
                ),
                trailing: _selectedStatusFilter == 'ALL'
                    ? const Icon(LucideIcons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedStatusFilter = 'ALL';
                  });
                  Navigator.of(modalContext).pop();
                },
              ),
              ListTile(
                title: const Text('Completed Trips'),
                leading: Icon(
                  LucideIcons.circle_check,
                  color: _selectedStatusFilter == 'COMPLETED'
                      ? AppTheme.primaryColor
                      : AppTheme.tertiaryColor,
                ),
                trailing: _selectedStatusFilter == 'COMPLETED'
                    ? const Icon(LucideIcons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedStatusFilter = 'COMPLETED';
                  });
                  Navigator.of(modalContext).pop();
                },
              ),
              ListTile(
                title: const Text('Cancelled Trips'),
                leading: Icon(
                  LucideIcons.circle_x,
                  color: _selectedStatusFilter == 'CANCELLED'
                      ? AppTheme.primaryColor
                      : AppTheme.tertiaryColor,
                ),
                trailing: _selectedStatusFilter == 'CANCELLED'
                    ? const Icon(LucideIcons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedStatusFilter = 'CANCELLED';
                  });
                  Navigator.of(modalContext).pop();
                },
              ),
              const SizedBox(height: 12),
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
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () {
            context.pop();
          },
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
            icon: const Icon(
              LucideIcons.funnel,
              color: AppTheme.primaryColor,
            ),
            onPressed: () {
              _displayTripHistoryFilterModalBottomSheet(context);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isActivityDataLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
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
                final groupingDateKey = _groupedActivityRides.keys.elementAt(sectionIndex);
                final groupedRideItems = _groupedActivityRides[groupingDateKey]!;
                final dailyCompletedRidesTotal = _calculateDailyCompletedTotalSum(groupedRideItems);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            groupingDateKey.toUpperCase(),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor.withValues(alpha: 0.4),
                              letterSpacing: 1.2,
                            ),
                          ),
                          if (dailyCompletedRidesTotal > 0)
                            Text(
                              '₱${dailyCompletedRidesTotal.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF00897B),
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...groupedRideItems.map((rideItem) => _buildActivityCard(rideItem)),
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
    final isTripCompleted = ride.status == 'completed';
    final dateStringParts = ride.date.split(',');
    final formattedActivityTime = dateStringParts.length > 1 ? dateStringParts[1].trim() : '';

    final estimatedDistanceInKm = _calculateCoordinatesDistanceInKm(
          ride.pickupLat,
          ride.pickupLng,
          ride.destLat,
          ride.destLng,
        ) * 1.3;
    final estimatedDurationInMinutes = (estimatedDistanceInKm * 2.5).round();

    final totalTripPrice = double.tryParse(ride.price) ?? 0.0;
    final calculatedDriverTip = totalTripPrice > 200 ? 40.0 : (totalTripPrice > 100 ? 20.0 : 0.0);
    final calculatedBaseFare = totalTripPrice - calculatedDriverTip;

    final driverInitials = _formattedDriverInitials(ride.driverName);
    final driverRating = _formattedDriverRating(ride.driverId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderSide.withValues(alpha: 0.2),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (isTripCompleted) {
              unawaited(
                context.pushNamed(ActivityRoutes.activityViewDetails, extra: ride),
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
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isTripCompleted ? 'completed' : 'cancelled',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isTripCompleted
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0D47A1),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        driverInitials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ride.driverName.isNotEmpty ? ride.driverName : 'Driver',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    if (isTripCompleted) ...[
                      const Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        driverRating,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                if (isTripCompleted) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 4, left: 16, right: 16),
                        child: Column(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1E88E5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            Container(
                              width: 2,
                              height: 24,
                              color: AppTheme.outlineBorderColor,
                            ),
                            Container(
                              width: 8,
                              height: 8,
                              color: const Color(0xFFB0BEC5),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ride.pickup,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              ride.destination,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: AppTheme.borderSide),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.route,
                        size: 16,
                        color: AppTheme.tertiaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${estimatedDistanceInKm.toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        LucideIcons.clock,
                        size: 16,
                        color: AppTheme.tertiaryColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$estimatedDurationInMinutes min',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppTheme.borderSide),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'fare ₱${calculatedBaseFare.toStringAsFixed(0)} + tip ₱${calculatedDriverTip.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        '₱${totalTripPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      'Passenger cancelled before pickup',
                      style: TextStyle(
                        fontSize: 14,
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

  double _calculateCoordinatesDistanceInKm(double startLatitude, double startLongitude, double endLatitude, double endLongitude) {
    const degreesToRadiansMultiplier = 0.017453292519943295;
    final haversineInterimValue = 0.5 - cos((endLatitude - startLatitude) * degreesToRadiansMultiplier) / 2 +
        cos(startLatitude * degreesToRadiansMultiplier) * cos(endLatitude * degreesToRadiansMultiplier) *
        (1 - cos((endLongitude - startLongitude) * degreesToRadiansMultiplier)) / 2;
    return 12742 * asin(sqrt(haversineInterimValue)); // 2 * R; R = 6371 km
  }

  double _calculateDailyCompletedTotalSum(List<RideHistoryModel> ridesForDate) {
    double dailySum = 0.0;
    for (final ride in ridesForDate) {
      if (ride.status == 'completed') {
        dailySum += double.tryParse(ride.price) ?? 0.0;
      }
    }
    return dailySum;
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
        final activityRepositoryInstance = Modular.get<ActivityRepository>();
        final retrievedRidesHistoryResult = await activityRepositoryInstance.fetchRideHistory(storedPassengerId);
        if (mounted) {
          retrievedRidesHistoryResult.fold(
            (failure) {
              setState(() {
                _retrievedRidesList = const [];
                _networkErrorMessage = failure.message;
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
          _networkErrorMessage = exceptionError.toString();
          _isActivityDataLoading = false;
        });
      }
    }
  }

  String _formattedDriverInitials(String driverName) {
    if (driverName.isEmpty) return 'D';
    final nameParts = driverName.trim().split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return nameParts[0][0].toUpperCase();
  }

  String _formattedDriverRating(String driverId) {
    if (driverId.isEmpty) return '4.9';
    final hashCodeValue = driverId.hashCode.abs();
    final calculatedRating = 4.5 + (hashCodeValue % 6) * 0.1;
    return calculatedRating.toStringAsFixed(1);
  }

  String _getGroupingDateKey(RideHistoryModel ride) {
    final dateStringParts = ride.date.split(',');
    if (dateStringParts.isEmpty) return 'Unknown';
    final extractedDatePart = dateStringParts[0].trim();

    try {
      final currentDateTime = DateTime.now();
      final todayDateString = '${_monthAbbreviationsList[currentDateTime.month - 1]} ${currentDateTime.day}';
      final yesterdayDateTime = currentDateTime.subtract(const Duration(days: 1));
      final yesterdayDateString =
          '${_monthAbbreviationsList[yesterdayDateTime.month - 1]} ${yesterdayDateTime.day}';

      if (extractedDatePart.toUpperCase() == todayDateString.toUpperCase()) {
        return 'Today';
      } else if (extractedDatePart.toUpperCase() == yesterdayDateString.toUpperCase()) {
        return 'Yesterday';
      }
    } catch (_) {}

    if (extractedDatePart.length >= 3) {
      final extractedMonthString = extractedDatePart.substring(0, 3).toLowerCase();
      final capitalizedMonthString = extractedMonthString[0].toUpperCase() + extractedMonthString.substring(1);
      final remainingDateString = extractedDatePart.substring(3);
      return '$capitalizedMonthString$remainingDateString';
    }

    return extractedDatePart;
  }
}
