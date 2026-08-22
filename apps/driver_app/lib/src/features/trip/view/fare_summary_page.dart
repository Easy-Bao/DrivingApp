import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/home/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/home_routes.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_core/shared_core.dart';

class FareSummaryPage extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;

  const FareSummaryPage({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.distance,
    required this.fare,
    required this.duration,
  });

  @override
  State<FareSummaryPage> createState() => _FareSummaryPageState();
}

class _FareSummaryPageState extends State<FareSummaryPage> {
  bool _isSubmitting = false;
  String? _error;

  Future<void> _confirmCashPayment() async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final cubit = BlocProvider.of<RideFlowCubit>(context);
      final fare = await cubit.confirmCashPayment();
      if (!mounted) return;
      if (fare == null) {
        setState(() {
          _isSubmitting = false;
          _error = 'Payment could not be confirmed. Please try again.';
        });
        return;
      }

      final dashboardCubit = Modular.get<DashboardCubit>();
      final wasOnline = dashboardCubit.state.isOnline;
      cubit.reset();
      if (wasOnline) {
        final position =
            LocationService.lastPosition ??
            await LocationService.getCurrentPosition();
        if (position != null) {
          await dashboardCubit.refreshOnlinePresence(
            lat: position.latitude,
            lng: position.longitude,
          );
        }
      }
      await dashboardCubit.loadStats();
      if (!mounted) return;
      context.goNamed(HomeRoutes.dashboard);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = 'Payment could not be confirmed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildAmountCard(),
                          const SizedBox(height: 12),
                          _buildTripCard(),
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            _buildError(),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _confirmCashPayment,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(LucideIcons.check, size: 18),
                      label: Text(
                        _isSubmitting
                            ? 'Confirming payment…'
                            : 'Confirm cash collected',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.complete,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => context.goNamed(HomeRoutes.dashboard),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          padding: EdgeInsets.zero,
          icon: const Icon(
            LucideIcons.arrow_left,
            size: 21,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cash collection',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Confirm after receiving payment',
                style: TextStyle(fontSize: 12, color: AppTheme.tertiaryColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.banknote,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collect from passenger',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '₱${widget.fare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
            ),
            child: const Text(
              'Cash',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildPlace(
            icon: LucideIcons.circle_dot,
            label: 'Pickup',
            address: widget.pickup,
            color: AppTheme.complete,
          ),
          const Padding(
            padding: EdgeInsets.only(left: 6, top: 5, bottom: 5),
            child: SizedBox(
              height: 12,
              width: 1,
              child: ColoredBox(color: AppTheme.borderSide),
            ),
          ),
          _buildPlace(
            icon: LucideIcons.map_pin,
            label: 'Drop Off',
            address: widget.dropoff,
            color: AppTheme.accent,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            children: [
              _buildMetric(
                icon: LucideIcons.route,
                value: DistanceFormatter.fromKilometers(widget.distance),
              ),
              const SizedBox(width: 8),
              _buildMetric(icon: LucideIcons.clock, value: widget.duration),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlace({
    required IconData icon,
    required String label,
    required String address,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.tertiaryColor,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
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

  Widget _buildMetric({required IconData icon, required String value}) {
    return Expanded(
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: AppTheme.tertiaryColor),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.cancel.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _error!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppTheme.cancel,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
