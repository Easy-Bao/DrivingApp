import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:driver/src/features/active_ride/domain/services/ride_payment_completion_handler.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver/src/features/active_ride/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_safety_report_sheet.dart';
import 'package:driver/src/features/dashboard/dashboard_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';

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
  required this.ridePaymentCompletionHandler,
  this.rideId,
  this.rideRepository,
}) extends StatefulWidget {
  final String pickup;
  final String dropoff;
  final String duration;
  final double distance;
  final double fare;
  final RidePaymentCompletionHandler ridePaymentCompletionHandler;
  final String? rideId;
  final RideRepository? rideRepository;

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

  void _onCashReceivedChanged(String value) {
    if (_error != null) setState(() => _error = null);
    if (_cashOutcome != 'paid') return;
    final receivedCents = _parseCashInput(value);
    if (receivedCents != null && receivedCents >= _fareAmountCents) {
      final changeCents = receivedCents - _fareAmountCents;
      _cashChangeController.text = _formatCashInput(changeCents);
    } else {
      _cashChangeController.text = '0.00';
    }
  }

  void _applyDenomination(int amountInPesos) {
    if (_isSubmitting) return;
    final amountCents = amountInPesos * 100;
    _cashReceivedController.text = _formatCashInput(amountCents);
    if (_cashOutcome == 'paid') {
      final changeCents = amountCents >= _fareAmountCents
          ? amountCents - _fareAmountCents
          : 0;
      _cashChangeController.text = _formatCashInput(changeCents);
    }
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  void _applyExactAmount() {
    if (_isSubmitting) return;
    _cashReceivedController.text = _formatCashInput(_fareAmountCents);
    _cashChangeController.text = '0.00';
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  List<int> get _suggestedBills {
    final farePesos = widget.fare;
    final standardBills = [50, 100, 200, 500, 1000];
    final bills = standardBills.where((b) => b >= farePesos).toList();
    if (bills.isEmpty) {
      final nextThousand = ((farePesos / 500).ceil()) * 500;
      bills.add(nextThousand);
    }
    return bills.take(4).toList();
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
          _error =
              cubit.state.failureMessage ??
              'Payment could not be confirmed. Please try again.';
        });
        return;
      }

      final rideId = cubit.activeRideId;
      if (rideId == null || rideId.isEmpty) {
        setState(() {
          _isSubmitting = false;
          _error =
              cubit.state.failureMessage ??
              'Payment could not be confirmed. Please try again.';
        });
        return;
      }

      setState(() => _canLeavePage = true);
      await cubit.reset();
      await widget.ridePaymentCompletionHandler.afterCashPayment(
        rideId: rideId,
      );
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
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.all(AppLayout.pagePadding),
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildAmountCard(),
                  const SizedBox(height: 24),
                  _buildCashCollectionForm(),
                  const SizedBox(height: 16),
                  _buildTripCard(),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    _buildError(),
                  ],
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _confirmCashPayment,
                  child: _isSubmitting
                      ? const Padding(
                          padding: EdgeInsets.all(4),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Text(_cashButtonLabel, textAlign: TextAlign.center),
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
                'Record what the passenger paid.',
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
            'Choose the outcome, then check the amount received.',
            style: TextStyle(
              fontSize: 12,
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          AppSelectField<String>(
            key: const ValueKey('cash-outcome-dropdown'),
            value: _cashOutcome,
            menuTitle: 'Payment outcome',
            decoration: const InputDecoration(labelText: 'Payment outcome'),
            options: [
              for (final entry in _cashOutcomeLabels.entries)
                AppSelectOption<String>(value: entry.key, label: entry.value),
            ],
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
              onChanged: _onCashReceivedChanged,
            ),
            if (_cashOutcome == 'paid') ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ActionChip(
                    key: const ValueKey('chip-exact-fare'),
                    label: const Text('Exact'),
                    onPressed: _isSubmitting ? null : _applyExactAmount,
                    avatar: const Icon(LucideIcons.check, size: 14),
                  ),
                  for (final bill in _suggestedBills)
                    ActionChip(
                      key: ValueKey('chip-bill-$bill'),
                      label: Text('₱$bill'),
                      onPressed: _isSubmitting
                          ? null
                          : () => _applyDenomination(bill),
                    ),
                ],
              ),
            ],
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cash to collect',
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colorScheme.onPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatPesoAmount(widget.fare),
            style: context.textStyles.headlineLarge?.copyWith(
              color: context.colorScheme.onPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard() {
    return ExpansionTile(
      title: const Text('Trip details'),
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 16),
      children: [
        CompactRouteTimeline(pickup: widget.pickup, dropoff: widget.dropoff),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildMetric(
              icon: LucideIcons.route,
              value: DistanceFormatter.fromKilometers(widget.distance),
            ),
            _buildMetric(icon: LucideIcons.clock, value: widget.duration),
          ],
        ),
        if (widget.rideId?.isNotEmpty == true && widget.rideRepository != null)
          SafetyReportButton(
            rideId: widget.rideId,
            rideRepository: widget.rideRepository!,
          ),
      ],
    );
  }

  Widget _buildMetric({required IconData icon, required String value}) {
    return Expanded(
      child: Container(
        constraints: const BoxConstraints(minHeight: 42),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppRadius.md),
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
    return AppErrorBanner(
      message: _error!,
      onRetry: _confirmCashPayment,
      onDismiss: () => setState(() => _error = null),
    );
  }
}
