import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/home/home_routes.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/trip_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class FareSummaryScreen extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;

  const FareSummaryScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  @override
  State<FareSummaryScreen> createState() => _FareSummaryScreenState();
}

class _FareSummaryScreenState extends State<FareSummaryScreen> {
  bool _isSubmitting = false;
  String? _error;

  Future<void> _confirmCashPayment() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final cubit = BlocProvider.of<RideFlowCubit>(context);
    final passengerId = cubit.activePassengerId;
    final rideId = cubit.activeRideId;
    final fare = await cubit.confirmCashPayment();
    if (!mounted) return;

    if (fare == null) {
      setState(() {
        _isSubmitting = false;
        _error =
            'Unable to confirm payment. Check your connection and try again.';
      });
      return;
    }

    if (passengerId == null || passengerId.isEmpty || rideId == null) {
      context.goNamed(HomeRoutes.dashboard);
      return;
    }
    context.pushReplacementNamed(
      TripRoutes.ratePassenger,
      extra: {
        'rideId': rideId,
        'passengerId': passengerId,
        'passengerName': cubit.activePassengerName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 28),
              _buildFareHero(),
              const SizedBox(height: 20),
              _buildSummaryCard(),
              const SizedBox(height: 12),
              _buildPaymentMethod(),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.cancel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              _buildConfirmButton(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Fare Summary',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Collect payment from passenger',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.primaryColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildFareHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            'SERVER-CALCULATED FARE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.55),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₱${widget.fare.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.banknote,
                  size: 13,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Cash',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        children: [
          _line('Pickup', widget.pickup),
          const SizedBox(height: 12),
          _line('Drop-off', widget.dropoff),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppTheme.borderSide),
          ),
          _line('Distance', '${widget.distance.toStringAsFixed(1)} km'),
          const SizedBox(height: 12),
          _line('Duration', widget.duration),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppTheme.borderSide),
          ),
          _line('Total', '₱${widget.fare.toStringAsFixed(2)}', isBold: true),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(LucideIcons.banknote, size: 18, color: AppTheme.primaryColor),
          SizedBox(width: 12),
          Text(
            'Cash Payment',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    final active = !_isSubmitting;
    return GestureDetector(
      onTap: active ? _confirmCashPayment : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 68,
        decoration: BoxDecoration(
          color: active
              ? AppTheme.complete
              : AppTheme.complete.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(34),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppTheme.complete.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.hand_coins, color: Colors.white, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Confirm Cash Collected',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _line(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isBold ? 18 : 14,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
