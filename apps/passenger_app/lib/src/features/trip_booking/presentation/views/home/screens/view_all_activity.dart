import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/di/service_locator.dart';
import 'package:passenger_app/src/core/themes/app_themes.dart';
import 'package:passenger_app/src/features/trip_booking/domain/repositories/activity_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PassengerViewAllActivity extends StatefulWidget {
  const PassengerViewAllActivity({super.key});

  @override
  State<PassengerViewAllActivity> createState() =>
      _PassengerViewAllActivityState();
}

class _PassengerViewAllActivityState extends State<PassengerViewAllActivity> {
  List<RideHistoryModel> _rides = [];
  bool _isLoading = true;
  String _errorMessage = '';

  static const _monthAbbreviations = [
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

  @override
  void initState() {
    super.initState();
    unawaited(_fetchActivity());
  }

  Future<void> _fetchActivity() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final passengerId = prefs.getString('passenger_id') ?? '';
      if (passengerId.isNotEmpty) {
        final repo = getIt<ActivityRepository>();
        final result = await repo.fetchRideHistory(passengerId);
        if (mounted) {
          result.fold(
            (failure) {
              setState(() {
                _rides = const [];
                _errorMessage = failure.message;
                _isLoading = false;
              });
            },
            (list) {
              setState(() {
                _rides = list;
                _isLoading = false;
              });
            },
          );
        }
      } else {
        if (mounted) {
          setState(() {
            _rides = const [];
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _getDateKey(RideHistoryModel ride) {
    final parts = ride.date.split(',');
    if (parts.isEmpty) return 'Unknown';
    final datePart = parts[0].trim();

    try {
      final now = DateTime.now();
      final todayStr = '${_monthAbbreviations[now.month - 1]} ${now.day}';
      final yesterday = now.subtract(const Duration(days: 1));
      final yesterdayStr =
          '${_monthAbbreviations[yesterday.month - 1]} ${yesterday.day}';

      if (datePart.toUpperCase() == todayStr.toUpperCase()) {
        return 'Today';
      } else if (datePart.toUpperCase() == yesterdayStr.toUpperCase()) {
        return 'Yesterday';
      }
    } catch (_) {}

    if (datePart.length >= 3) {
      final month = datePart.substring(0, 3).toLowerCase();
      final capitalizedMonth = month[0].toUpperCase() + month.substring(1);
      final rest = datePart.substring(3);
      return '$capitalizedMonth$rest';
    }

    return datePart;
  }

  Map<String, List<RideHistoryModel>> get _groupedRides {
    final Map<String, List<RideHistoryModel>> grouped = {};
    for (final ride in _rides) {
      final key = _getDateKey(ride);
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(ride);
    }
    return grouped;
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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Recent Activity',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _errorMessage.isNotEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: AppTheme.cancel,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : _rides.isEmpty
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
              itemCount: _groupedRides.keys.length,
              itemBuilder: (context, sectionIndex) {
                final dateKey = _groupedRides.keys.elementAt(sectionIndex);
                final items = _groupedRides[dateKey]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 4,
                      ),
                      child: Text(
                        dateKey.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    ...items.map((item) => _buildActivityCard(item)),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildActivityCard(RideHistoryModel ride) {
    final isCompleted = ride.status == 'completed';
    final parts = ride.date.split(',');
    final timeStr = parts.length > 1 ? parts[1].trim() : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outlineBorderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.unselectedItemColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.complete.withValues(alpha: 0.5)
                      : AppTheme.cancel,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ride.status.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.surface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 18,
                    color: AppTheme.outlineBorderColor,
                  ),
                  const Icon(
                    Icons.location_on,
                    size: 12,
                    color: AppTheme.tertiaryColor,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.pickup,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ride.destination,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                ride.price,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppTheme.borderSide),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.directions_car,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              TextButton(
                onPressed: () {
                  if (isCompleted) {
                    unawaited(
                      context.pushNamed('ActivityViewDetails', extra: ride),
                    );
                  } else {
                    unawaited(context.pushNamed('SearchDestination'));
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isCompleted ? 'View Details' : 'Rebook',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
