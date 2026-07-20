import 'package:driver_app/src/features/activity/domain/repositories/driver_activity_repository.dart';
import 'package:driver_app/src/features/activity/activity_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverTripHistoryScreen extends StatefulWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  State<DriverTripHistoryScreen> createState() =>
      _DriverTripHistoryScreenState();
}

class _DriverTripHistoryScreenState extends State<DriverTripHistoryScreen> {
  bool _isLoading = true;
  List<dynamic> _trips = [];
  String _selectedTripStatusFilter = 'ALL';

  List<dynamic> get _filteredTripsList {
    if (_selectedTripStatusFilter == 'ALL') {
      return _trips;
    }
    return _trips.where((tripRecord) {
      final statusString = (tripRecord['status'] as String? ?? '').toUpperCase();
      return statusString == _selectedTripStatusFilter;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final prefs = await SharedPreferences.getInstance();
    final driverId = prefs.getString('driver_id') ?? '';
    if (driverId.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    final result = await Modular.get<DriverActivityRepository>().fetchTripHistory(
      driverId,
    );
    if (mounted) {
      result.fold(
        (failure) {
          setState(() {
            _trips = const [];
            _isLoading = false;
          });
        },
        (trips) {
          setState(() {
            _trips = trips;
            _isLoading = false;
          });
        },
      );
    }
  }

  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final tripDate = DateTime(dt.year, dt.month, dt.day);

      if (tripDate == today) {
        return 'Today';
      } else if (tripDate == yesterday) {
        return 'Yesterday';
      } else {
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
        return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
      }
    } catch (_) {
      return 'Past Trip';
    }
  }

  void _displayDriverTripHistoryFilterModalBottomSheet(BuildContext context) {
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
                  color: _selectedTripStatusFilter == 'ALL'
                      ? AppTheme.primaryColor
                      : AppTheme.tertiaryColor,
                ),
                trailing: _selectedTripStatusFilter == 'ALL'
                    ? const Icon(LucideIcons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedTripStatusFilter = 'ALL';
                  });
                  Navigator.of(modalContext).pop();
                },
              ),
              ListTile(
                title: const Text('Completed Trips'),
                leading: Icon(
                  LucideIcons.circle_check,
                  color: _selectedTripStatusFilter == 'COMPLETED'
                      ? AppTheme.primaryColor
                      : AppTheme.tertiaryColor,
                ),
                trailing: _selectedTripStatusFilter == 'COMPLETED'
                    ? const Icon(LucideIcons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedTripStatusFilter = 'COMPLETED';
                  });
                  Navigator.of(modalContext).pop();
                },
              ),
              ListTile(
                title: const Text('Cancelled Trips'),
                leading: Icon(
                  LucideIcons.circle_x,
                  color: _selectedTripStatusFilter == 'CANCELLED'
                      ? AppTheme.primaryColor
                      : AppTheme.tertiaryColor,
                ),
                trailing: _selectedTripStatusFilter == 'CANCELLED'
                    ? const Icon(LucideIcons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    _selectedTripStatusFilter = 'CANCELLED';
                  });
                  Navigator.of(modalContext).pop();
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Map<String, List<dynamic>> _groupByDate(List<dynamic> trips) {
    final map = <String, List<dynamic>>{};
    for (final t in trips) {
      final dateStr = _formatDate(t['created_at'] as String? ?? '');
      map.putIfAbsent(dateStr, () => []).add(t);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(_filteredTripsList);

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
          'Trip History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              LucideIcons.funnel,
              color: AppTheme.primaryColor,
            ),
            onPressed: () => _displayDriverTripHistoryFilterModalBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            )
          : _filteredTripsList.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.history,
                    size: 64,
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No trip history found',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
              physics: const BouncingScrollPhysics(),
              itemCount: grouped.keys.length,
              itemBuilder: (context, groupIndex) {
                final date = grouped.keys.elementAt(groupIndex);
                final trips = grouped[date]!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 12),
                      child: Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor.withValues(alpha: 0.4),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    ...trips.map(_buildTripCard),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildTripCard(dynamic trip) {
    final status = trip['status'] as String? ?? 'completed';
    final isCompleted = status == 'completed';
    final statusColor = isCompleted ? AppTheme.complete : AppTheme.cancel;
    final statusLabel = isCompleted ? 'Completed' : 'Canceled';
    final fromName = trip['pickup_name'] as String? ?? 'Pickup';
    final toName = trip['dropoff_name'] as String? ?? 'Dropoff';
    final fareAmt = (trip['fare'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: () => context.pushNamed(
        ActivityRoutes.tripDetail,
        extra: trip as Map<String, dynamic>,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(width: 1, height: 22, color: AppTheme.borderSide),
                  const Icon(
                    Icons.location_on,
                    size: 12,
                    color: AppTheme.tertiaryColor,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fromName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    toName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${fareAmt.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
