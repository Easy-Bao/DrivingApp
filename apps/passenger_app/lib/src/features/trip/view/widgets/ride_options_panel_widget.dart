import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/trip/view/widgets/ride_fare_details_widget.dart';
import 'package:passenger_app/src/features/trip/view/widgets/ride_tip_selector_widget.dart';
import 'package:passenger_app/src/features/trip/view/widgets/ride_trip_summary_widget.dart';
import 'package:shared_core/shared_core.dart';

class RideOptionsPanelWidget extends StatefulWidget {
  final String passengerName;
  final String pickupLabel;
  final String destinationName;
  final String destinationAddress;
  final FareResult? fareResult;
  final VoidCallback onBookPressed;
  final TextEditingController customFareController;
  final String? customFareError;
  final bool isLoadingFare;
  final String? fareError;
  final VoidCallback? onRetryFare;
  final ValueChanged<String> onCustomFareChanged;
  final VoidCallback onUseCalculatedFare;
  final TextEditingController notesController;
  final ValueChanged<String> onNotesChanged;
  final int selectedTipAmount;
  final ValueChanged<int> onTipSelected;
  final double totalFare;

  const RideOptionsPanelWidget({
    super.key,
    required this.passengerName,
    required this.pickupLabel,
    required this.destinationName,
    required this.destinationAddress,
    required this.fareResult,
    required this.onBookPressed,
    required this.customFareController,
    required this.customFareError,
    required this.isLoadingFare,
    required this.fareError,
    required this.onRetryFare,
    required this.onCustomFareChanged,
    required this.onUseCalculatedFare,
    required this.notesController,
    required this.onNotesChanged,
    required this.selectedTipAmount,
    required this.onTipSelected,
    required this.totalFare,
  });

  @override
  State<RideOptionsPanelWidget> createState() => _RideOptionsPanelWidgetState();
}

enum _RideOptionsPanelView { summary, customOffer, tripNote, fareDetails }

class _RideOptionsPanelWidgetState extends State<RideOptionsPanelWidget> {
  _RideOptionsPanelView _currentView = _RideOptionsPanelView.summary;

  FareResult? get _fareResult => widget.fareResult;

  double? get _minimumFare => _fareResult?.totalFare;

  double? get _enteredFare =>
      double.tryParse(widget.customFareController.text.trim());

  bool get _hasValidFare {
    final minimumFare = _minimumFare;
    final enteredFare = _enteredFare;
    return minimumFare != null &&
        enteredFare != null &&
        enteredFare >= minimumFare &&
        widget.customFareError == null;
  }

  String _currency(double amount) => '₱${amount.toStringAsFixed(2)}';

  void _showView(_RideOptionsPanelView view) {
    if (!mounted) return;
    setState(() => _currentView = view);
  }

  void _saveCustomOffer() {
    if (_hasValidFare) {
      _showView(_RideOptionsPanelView.summary);
    }
  }

  void _restoreCalculatedFare() {
    widget.onUseCalculatedFare();
    _showView(_RideOptionsPanelView.summary);
  }

  Widget _buildFareStatus() {
    if (widget.isLoadingFare) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text('Calculating your fare…'),
          ],
        ),
      );
    }

    final error = widget.fareError;
    if (error == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: Text('Fare details are unavailable.')),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cancel.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cancel.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.cancel, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error,
                  style: const TextStyle(
                    color: AppTheme.cancel,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          if (widget.onRetryFare != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.onRetryFare,
                child: const Text('Try again'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionRow({
    required Key key,
    required IconData icon,
    required String title,
    required String details,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderSide),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.neutralColor,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.tertiaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                LucideIcons.chevron_right,
                color: AppTheme.tertiaryColor,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTotalFareCard() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('fare-summary'),
        onTap: _hasValidFare
            ? () => _showView(_RideOptionsPanelView.fareDetails)
            : null,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.neutralColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderSide),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total fare',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'View fare calculation',
                      style: TextStyle(
                        color: AppTheme.tertiaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _currency(widget.totalFare),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(LucideIcons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelHeader({required String title, required String details}) {
    return Row(
      children: [
        IconButton(
          key: const ValueKey('panel-back'),
          onPressed: () => _showView(_RideOptionsPanelView.summary),
          tooltip: 'Back to trip summary',
          icon: const Icon(LucideIcons.arrow_left, size: 20),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                details,
                style: const TextStyle(
                  color: AppTheme.tertiaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryContent() {
    final fareResult = _fareResult;
    final enteredFare = _enteredFare;
    final minimumFare = _minimumFare;
    final hasCustomOffer =
        minimumFare != null && enteredFare != null && enteredFare > minimumFare;
    final note = widget.notesController.text.trim();

    return Column(
      key: const ValueKey('trip-summary-content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RideTripSummaryWidget(
          pickupLabel: widget.pickupLabel,
          destinationName: widget.destinationName,
          destinationAddress: widget.destinationAddress,
        ),
        const SizedBox(height: 16),
        if (fareResult == null)
          _buildFareStatus()
        else ...[
          _buildActionRow(
            key: const ValueKey('custom-offer-trigger'),
            icon: LucideIcons.sliders_horizontal,
            title: 'Set your offer',
            details: hasCustomOffer
                ? 'Your offer: ${_currency(enteredFare)}'
                : 'Optional · use a fare above the calculated minimum',
            onTap: () => _showView(_RideOptionsPanelView.customOffer),
          ),
          const SizedBox(height: 16),
          RideTipSelectorWidget(
            selectedTipAmount: widget.selectedTipAmount,
            onTipSelected: widget.onTipSelected,
          ),
          const SizedBox(height: 16),
          _buildActionRow(
            key: const ValueKey('trip-note-trigger'),
            icon: LucideIcons.file_text,
            title: 'Add a trip note',
            details: note.isEmpty
                ? 'Optional pickup or accessibility instructions'
                : 'Note added',
            onTap: () => _showView(_RideOptionsPanelView.tripNote),
          ),
          const SizedBox(height: 12),
          _buildTotalFareCard(),
          const SizedBox(height: 12),
        ],
        ElevatedButton(
          onPressed: _hasValidFare ? widget.onBookPressed : null,
          child: Text(
            fareResult == null
                ? widget.isLoadingFare
                      ? 'Calculating fare…'
                      : 'Fare unavailable'
                : 'Find a driver',
          ),
        ),
      ],
    );
  }

  Widget _buildCustomOfferContent() {
    final minimumFare = _minimumFare;
    if (minimumFare == null) return _buildSummaryContent();

    return Column(
      key: const ValueKey('custom-offer-content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPanelHeader(
          title: 'Set your offer',
          details: 'Offers cannot be below the calculated fare.',
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.neutralColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderSide),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Calculated minimum',
                style: TextStyle(color: AppTheme.tertiaryColor, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                _currency(minimumFare),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Divider(height: 28),
              TextField(
                key: const ValueKey('custom-offer-input'),
                controller: widget.customFareController,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
                onChanged: (value) {
                  widget.onCustomFareChanged(value);
                  setState(() {});
                },
                decoration: InputDecoration(
                  labelText: 'Your offer',
                  prefixText: '₱ ',
                  helperText: 'Enter a higher amount if you want to adjust it.',
                  errorText: widget.customFareError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.borderSide),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _restoreCalculatedFare,
                  icon: const Icon(LucideIcons.rotate_ccw, size: 16),
                  label: const Text('Use calculated fare'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          key: const ValueKey('custom-offer-save'),
          onPressed: _hasValidFare ? _saveCustomOffer : null,
          child: const Text('Save offer'),
        ),
      ],
    );
  }

  Widget _buildTripNoteContent() {
    return Column(
      key: const ValueKey('trip-note-content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPanelHeader(
          title: 'Add a trip note',
          details: 'Keep instructions short and useful for pickup.',
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.neutralColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderSide),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Trip note (optional)',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Share a concise pickup instruction when it helps.',
                style: TextStyle(color: AppTheme.tertiaryColor, fontSize: 12),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const ValueKey('trip-note-input'),
                controller: widget.notesController,
                autofocus: true,
                minLines: 3,
                maxLines: 4,
                maxLength: 160,
                textCapitalization: TextCapitalization.sentences,
                onChanged: (value) {
                  widget.onNotesChanged(value);
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'For example: Meet me at the side entrance.',
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: const TextStyle(
                    color: AppTheme.tertiaryColor,
                    fontSize: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.borderSide),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTheme.borderSide),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryColor,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          key: const ValueKey('trip-note-save'),
          onPressed: () => _showView(_RideOptionsPanelView.summary),
          child: const Text('Save note'),
        ),
      ],
    );
  }

  Widget _buildFareDetailsContent(FareResult fareResult) {
    return Column(
      key: const ValueKey('fare-details-content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RideFareDetailsWidget(
          passengerName: widget.passengerName,
          fareResult: fareResult,
          offeredFare: _enteredFare ?? fareResult.totalFare,
          tipAmount: widget.selectedTipAmount,
          totalFare: widget.totalFare,
          onBackPressed: () => _showView(_RideOptionsPanelView.summary),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final fareResult = _fareResult;
    return switch (_currentView) {
      _RideOptionsPanelView.summary => _buildSummaryContent(),
      _RideOptionsPanelView.customOffer => _buildCustomOfferContent(),
      _RideOptionsPanelView.tripNote => _buildTripNoteContent(),
      _RideOptionsPanelView.fareDetails when fareResult != null =>
        _buildFareDetailsContent(fareResult),
      _RideOptionsPanelView.fareDetails => _buildSummaryContent(),
    };
  }

  Offset _entryOffsetForCurrentView() {
    return switch (_currentView) {
      _RideOptionsPanelView.customOffer ||
      _RideOptionsPanelView.tripNote => const Offset(-0.12, 0),
      _RideOptionsPanelView.fareDetails => const Offset(0.12, 0),
      _RideOptionsPanelView.summary => const Offset(-0.08, 0),
    };
  }

  @override
  Widget build(BuildContext context) {
    final entryOffset = _entryOffsetForCurrentView();
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppTheme.borderSide,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) => ClipRect(
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      currentChild ?? const SizedBox.shrink(),
                    ],
                  ),
                ),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: entryOffset,
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
