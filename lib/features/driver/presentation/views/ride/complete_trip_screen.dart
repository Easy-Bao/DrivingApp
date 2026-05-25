import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

/// Confirmation screen shown immediately after completing a trip.
/// Shows route summary and routes to fare summary.
class CompleteTripScreen extends StatelessWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;

  const CompleteTripScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              _buildSuccessIcon(),
              const SizedBox(height: 20),
              const Text(
                'Trip Completed!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Great job, driver! 🎉',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 36),
              _buildSummaryCard(),
              const Spacer(),
              _buildEndRideButton(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: AppTheme.complete.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            color: AppTheme.complete,
            shape: BoxShape.circle,
          ),
          child: const Icon(LucideIcons.check, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        children: [
          _routeRow(LucideIcons.circle_dot, 'Pickup', pickup),
          const SizedBox(height: 14),
          _routeRow(LucideIcons.map_pin, 'Drop-off', dropoff),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppTheme.borderSide),
          ),
          Row(
            children: [
              Expanded(
                child: _statCell(
                  '${distance.toStringAsFixed(1)} km',
                  'Distance',
                ),
              ),
              Container(width: 1, height: 36, color: AppTheme.borderSide),
              Expanded(child: _statCell(duration, 'Duration')),
              Container(width: 1, height: 36, color: AppTheme.borderSide),
              Expanded(child: _statCell('₱${fare.toStringAsFixed(0)}', 'Fare')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _routeRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.tertiaryColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statCell(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _buildEndRideButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pushReplacementNamed(
        'FareSummary',
        extra: {
          'pickup': pickup,
          'dropoff': dropoff,
          'distance': distance,
          'fare': fare,
          'duration': duration,
        },
      ),
      child: Container(
        width: double.infinity,
        height: 68,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'COLLECT FARE',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
