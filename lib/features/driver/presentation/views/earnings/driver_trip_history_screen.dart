import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Redesigned trip history screen — chronological list of completed and canceled rides.
class DriverTripHistoryScreen extends StatelessWidget {
  const DriverTripHistoryScreen({super.key});

  static const _trips = [
    _Trip(
      'Today',
      'SM City Dipolog',
      'Dipolog Market',
      '₱52.00',
      '8 min',
      true,
    ),
    _Trip(
      'Today',
      'Turno, Dipolog',
      'Biasong, Dipolog',
      '₱38.00',
      '6 min',
      true,
    ),
    _Trip(
      'Yesterday',
      'Galas, Dipolog',
      'Olingan, Dipolog',
      '₱65.00',
      '12 min',
      true,
    ),
    _Trip(
      'Yesterday',
      'Central, Dipolog',
      'Sicayab, Dipolog',
      '₱45.00',
      '9 min',
      true,
    ),
    _Trip(
      'Yesterday',
      'Miputak, Dipolog',
      'Airport Rd, Dipolog',
      '₱72.00',
      '15 min',
      false,
    ),
    _Trip('May 17', 'Cogon Market', 'Sta. Filomena', '₱55.00', '10 min', true),
    _Trip(
      'May 17',
      'Boulevard, Dipolog',
      'Sunset Blvd',
      '₱30.00',
      '5 min',
      true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate(_trips);

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
      ),
      body: ListView.builder(
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

  Map<String, List<_Trip>> _groupByDate(List<_Trip> trips) {
    final map = <String, List<_Trip>>{};
    for (final t in trips) {
      map.putIfAbsent(t.date, () => []).add(t);
    }
    return map;
  }

  Widget _buildTripCard(_Trip trip) {
    final statusColor = trip.isCompleted ? AppTheme.complete : AppTheme.cancel;
    final statusLabel = trip.isCompleted ? 'Completed' : 'Canceled';

    return Container(
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
          // Route dot indicator
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
          // Route labels
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.from,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  trip.to,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          // Fare + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trip.fare,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
    );
  }
}

class _Trip {
  final String date;
  final String from;
  final String to;
  final String fare;
  final String time;
  final bool isCompleted;

  const _Trip(
    this.date,
    this.from,
    this.to,
    this.fare,
    this.time,
    this.isCompleted,
  );
}
