import 'dart:async';

import 'package:maps/maps.dart';
import 'package:driver/src/features/dashboard/presentation/bloc/dashboard/dashboard_cubit.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:foundation/foundation.dart';
import 'package:design_system/design_system.dart';

const _cashOutcomeLabels = <String, String>{
  'paid': 'Paid in full',
  'partial': 'Partial cash received',
  'refused': 'Passenger refused to pay',
  'unpaid': 'No cash received',
};

class const FareSummaryPage({
  super.key,
  required this.pickup,
  required this.dropoff,
  required this.distance,
  required this.fare,
  required this.duration,
  required this.dashboardCubit,
}) extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;
  final DashboardCubit dashboardCubit;

  @override
  State<FareSummaryPage> createState() => _FareSummaryPageState();
}

class _FareSummaryPageState extends State<FareSummaryPage> {
  late final TextEditingController _cashReceivedController;
  late final TextEditingController _cashChangeController;
  bool _isSubmitting = false;
  bool _canLeavePage = false;
  bool _isShowingExitPrompt = false;
  String? _error;
  String _cashOutcome = 'paid';

  @override
  void initState() {
    super.initState();
    _cashReceivedController = TextEditingController(
      text: _formatCashInput(_fareAmountCents),
    );
    _cashChangeController = TextEditingController(text: '0.00');
  }

  @override
  void dispose() {
    _cashReceivedController.dispose();
    _cashChangeController.dispose();
    super.dispose();
  }

  int get _fareAmountCents => (widget.fare * 100).round();

  String _formatCashInput(int amountCents) {
    return (amountCents / 100).toStringAsFixed(2);
  }

  int? _parseCashInput(String value) {
    final normalized = value.trim().replaceAll(',', '');
    if (normalized.isEmpty) return null;
    final amount = double.tryParse(normalized);
    if (amount == null || !amount.isFinite || amount < 0) return null;
    return (amount * 100).round();
  }

  String? _validateCashEntry({
    required int? receivedAmount,
    required int? changeAmount,
  }) {
    if (_fareAmountCents <= 0) return 'The payable fare is unavailable.';
    if (_cashOutcome == 'paid') {
      if (receivedAmount == null || changeAmount == null) {
        return 'Enter the cash received and change returned.';
      }
      if (changeAmount > receivedAmount) {
        return 'Change cannot be greater than the cash received.';
      }
      if (receivedAmount - changeAmount != _fareAmountCents) {
        return 'Cash received minus change must equal the fare.';
      }
    } else if (_cashOutcome == 'partial') {
      if (receivedAmount == null) return 'Enter the cash received.';
      if (receivedAmount <= 0 || receivedAmount >= _fareAmountCents) {
        return 'Partial cash must be more than zero and less than the fare.';
      }
    }
    return null;
  }

  Future<void> _confirmCashPayment() async {
    if (_isSubmitting) return;

    final receivedAmount = _cashOutcome == 'paid' || _cashOutcome == 'partial'
        ? _parseCashInput(_cashReceivedController.text)
        : 0;
    final changeAmount = _cashOutcome == 'paid'
        ? _parseCashInput(_cashChangeController.text)
        : 0;
    final validationMessage = _validateCashEntry(
      receivedAmount: receivedAmount,
      changeAmount: changeAmount,
    );
    if (validationMessage != null) {
      setState(() => _error = validationMessage);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      final cubit = BlocProvider.of<RideFlowCubit>(context);
      final fare = await cubit.confirmCashPayment(
        cashReceivedAmount: receivedAmount,
        cashChangeAmount: changeAmount ?? 0,
        cashOutcome: _cashOutcome,
      );
      if (!mounted) return;
      if (fare == null) {
        setState(() {
          _isSubmitting = false;
          _error = 'Payment could not be confirmed. Please try again.';
        });
        return;
      }

      setState(() => _canLeavePage = true);
      final dashboardCubit = widget.dashboardCubit;
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
      context.goNamed(DashboardRoutes.dashboard);
    } catch (_) {
      if (!mounted) return;
      if (_canLeavePage) {
        context.goNamed(DashboardRoutes.dashboard);
        return;
      }
      setState(() {
        _isSubmitting = false;
        _error = 'Payment could not be confirmed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<void>(
      canPop: _canLeavePage,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_showCashOutcomeRequired());
      },
      child: Scaffold(
        backgroundColor: context.canvasColor,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  EasyRideLayout.pagePadding,
                  12,
                  EasyRideLayout.pagePadding,
                  EasyRideLayout.pagePadding,
                ),
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
                            _buildCashCollectionForm(),
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
                              ? 'Recording cash outcome…'
                              : _cashButtonLabel,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.semanticColors.success,
                          foregroundColor: context.semanticColors.onSuccess,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              EasyRideRadius.lg,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
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
          key: const ValueKey('cash-summary-back-button'),
          onPressed: _isSubmitting ? null : _showCashOutcomeRequired,
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: const CircleBorder(),
          ),
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
                'Record the cash outcome after collection or refusal',
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

  Future<void> _showCashOutcomeRequired() async {
    if (!mounted || _canLeavePage || _isSubmitting || _isShowingExitPrompt) {
      return;
    }

    _isShowingExitPrompt = true;
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Cash outcome required'),
          content: const Text(
            'Record whether the fare was paid, partially paid, refused, or unpaid before leaving this trip.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Continue recording'),
            ),
          ],
        ),
      );
    } finally {
      _isShowingExitPrompt = false;
    }
  }

  String get _cashButtonLabel => switch (_cashOutcome) {
    'paid' => 'Confirm cash collected',
    'partial' => 'Record partial cash',
    'refused' || 'unpaid' => 'Record unpaid cash',
    _ => 'Record cash outcome',
  };

  Widget _buildCashCollectionForm() {
    final recordsAmount = _cashOutcome == 'paid' || _cashOutcome == 'partial';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EasyRideSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cash outcome',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose what happened in person. Digital payment is not used.',
            style: TextStyle(
              fontSize: 12,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const ValueKey('cash-outcome-dropdown'),
            initialValue: _cashOutcome,
            decoration: const InputDecoration(labelText: 'Payment outcome'),
            items: _cashOutcomeLabels.entries
                .map(
                  (entry) => DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: _isSubmitting
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() {
                      _cashOutcome = value;
                      _error = null;
                      if (value != 'paid') {
                        _cashChangeController.text = '0.00';
                      }
                    });
                  },
          ),
          if (recordsAmount) ...[
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('cash-received-field'),
              controller: _cashReceivedController,
              enabled: !_isSubmitting,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Cash received',
                prefixText: '₱ ',
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ],
          if (_cashOutcome == 'paid') ...[
            const SizedBox(height: 12),
            TextField(
              key: const ValueKey('cash-change-field'),
              controller: _cashChangeController,
              enabled: !_isSubmitting,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Change returned',
                prefixText: '₱ ',
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
          ],
          if (_cashOutcome == 'partial') ...[
            const SizedBox(height: 8),
            Text(
              'No change is recorded for a partial collection. The remaining fare stays unresolved.',
              style: TextStyle(
                fontSize: 12,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (_cashOutcome == 'refused' || _cashOutcome == 'unpaid') ...[
            const SizedBox(height: 8),
            Text(
              'No cash is recorded. This ride will be marked unpaid for follow-up.',
              style: TextStyle(
                fontSize: 12,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EasyRideSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.primary,
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
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
                    fontFeatures: const [FontFeature.tabularFigures()],
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
        borderRadius: BorderRadius.circular(EasyRideRadius.lg),
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
          borderRadius: BorderRadius.circular(EasyRideRadius.md),
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
                  fontFeatures: const [FontFeature.tabularFigures()],
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
        borderRadius: BorderRadius.circular(EasyRideRadius.md),
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
