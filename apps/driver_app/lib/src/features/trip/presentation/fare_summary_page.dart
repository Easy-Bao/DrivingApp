import 'package:driver_app/src/core/location/location.dart';
import 'package:driver_app/src/features/home/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver_app/src/features/home/home_routes.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

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
      backgroundColor: context.canvasColor,
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
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: context.semanticColors.onSuccess,
                              ),
                            )
                          : const Icon(LucideIcons.check, size: 18),
                      label: Text(
                        _isSubmitting
                            ? 'Confirming payment…'
                            : 'Confirm cash collected',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.semanticColors.success,
                        foregroundColor: context.semanticColors.onSuccess,
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
          style: IconButton.styleFrom(shape: const CircleBorder()),
          icon: Icon(
            LucideIcons.arrow_left,
            size: 21,
            color: context.colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cash collection',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Confirm after receiving payment',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colorScheme.onSurfaceVariant,
                ),
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
        color: context.colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: context.colorScheme.onPrimary.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.banknote,
              color: context.colorScheme.onPrimary,
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
                    color: context.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatPesoAmount(widget.fare),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: context.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: context.colorScheme.onPrimary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'Cash',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: context.colorScheme.onPrimary,
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
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Trip details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildPlace(
            icon: LucideIcons.circle_dot,
            label: 'Pickup',
            address: widget.pickup,
            color: context.semanticColors.success,
          ),
          Padding(
            padding: EdgeInsets.only(left: 6, top: 5, bottom: 5),
            child: SizedBox(
              height: 12,
              width: 1,
              child: ColoredBox(color: context.colorScheme.outlineVariant),
            ),
          ),
          _buildPlace(
            icon: LucideIcons.map_pin,
            label: 'Drop Off',
            address: widget.dropoff,
            color: context.colorScheme.primary,
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
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurfaceVariant,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.colorScheme.onSurface,
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
          color: context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: context.colorScheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: context.colorScheme.onSurface,
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
        color: context.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        _error!,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: context.colorScheme.error,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
