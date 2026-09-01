import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_fare_details_widget.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_tip_selector_widget.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_trip_summary_widget.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const RideOptionsPanelWidget({
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
  required this.notesController,
  required this.onNotesChanged,
  required this.selectedTipAmount,
  required this.onTipSelected,
  required this.totalFare,
}) extends StatefulWidget {
  final String passengerName;
  final String pickupLabel;
  final String destinationName;
  final String destinationAddress;
  final FareEstimate? fareResult;
  final VoidCallback onBookPressed;
  final TextEditingController customFareController;
  final String? customFareError;
  final bool isLoadingFare;
  final String? fareError;
  final VoidCallback? onRetryFare;
  final ValueChanged<String> onCustomFareChanged;
  final TextEditingController notesController;
  final ValueChanged<String> onNotesChanged;
  final int selectedTipAmount;
  final ValueChanged<int> onTipSelected;
  final double totalFare;

  @override
  State<RideOptionsPanelWidget> createState() => _RideOptionsPanelWidgetState();
}

enum _RideOptionsPanelView() {
  summary,
  customOffer,
  tripNote,
  fareDetails,
}

class _RideOptionsPanelWidgetState() extends State<RideOptionsPanelWidget> {
  static const _viewTransitionDuration = Duration(milliseconds: 160);

  _RideOptionsPanelView _currentView = _RideOptionsPanelView.summary;

  FareEstimate? get _fareResult => widget.fareResult;

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

  String _currency(double amount) => formatPesoAmount(amount);

  void _showView(_RideOptionsPanelView view) {
    if (!mounted) return;
    setState(() => _currentView = view);
  }

  void _saveCustomOffer() {
    if (_hasValidFare) {
      _showView(_RideOptionsPanelView.summary);
    }
  }

  Widget _buildLoadingContent() {
    return Skeletonizer.zone(
      key: const ValueKey('ride-options-loading'),
      child: Column(
        key: const ValueKey('ride-options-loading-content'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLoadingTripSummary(),
          const SizedBox(height: 16),
          _buildLoadingActionRow(),
          const SizedBox(height: 16),
          _buildLoadingTipSelector(),
          const SizedBox(height: 16),
          _buildLoadingActionRow(),
          const SizedBox(height: 12),
          _buildLoadingTotalFare(),
          const SizedBox(height: 12),
          const Bone.button(
            width: double.infinity,
            height: 50,
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingTripSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Bone.icon(size: 18),
              SizedBox(height: 10),
              Bone(width: 2, height: 38),
              SizedBox(height: 10),
              Bone.icon(size: 18),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(width: 48, fontSize: 11),
                SizedBox(height: 3),
                Bone.text(width: 140, fontSize: 14),
                SizedBox(height: 22),
                Bone.text(width: 78, fontSize: 11),
                SizedBox(height: 3),
                Bone.text(width: 120, fontSize: 14),
                SizedBox(height: 3),
                Bone.multiText(lines: 2, width: 210, fontSize: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingActionRow() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: const Row(
        children: [
          Bone.square(
            size: 40,
            borderRadius: BorderRadius.all(Radius.circular(13)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(width: 100, fontSize: 14),
                SizedBox(height: 4),
                Bone.text(width: 190, fontSize: 12),
              ],
            ),
          ),
          SizedBox(width: 8),
          Bone.icon(size: 19),
        ],
      ),
    );
  }

  Widget _buildLoadingTipSelector() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Bone.text(width: 72, fontSize: 14),
        SizedBox(height: 4),
        Bone.text(width: 190, fontSize: 12),
        SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Bone.button(
                width: 56,
                height: 34,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              SizedBox(width: 6),
              Bone.button(
                width: 50,
                height: 34,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              SizedBox(width: 6),
              Bone.button(
                width: 50,
                height: 34,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              SizedBox(width: 6),
              Bone.button(
                width: 50,
                height: 34,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              SizedBox(width: 6),
              Bone.button(
                width: 50,
                height: 34,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              SizedBox(width: 6),
              Bone.button(
                width: 56,
                height: 34,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingTotalFare() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Bone.text(width: 82, fontSize: 15),
                SizedBox(height: 4),
                Bone.text(width: 130, fontSize: 12),
              ],
            ),
          ),
          Bone.text(width: 56, fontSize: 20),
          SizedBox(width: 8),
          Bone.icon(size: 18),
        ],
      ),
    );
  }

  Widget _buildFareStatus() {
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
        color: context.colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colorScheme.error.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                color: context.colorScheme.error,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(
                    color: context.colorScheme.error,
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
      color: context.colorScheme.surface.withValues(alpha: 0),
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: context.colorScheme.onSurface,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevron_right,
                color: context.colorScheme.onSurfaceVariant,
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
      color: context.colorScheme.surface.withValues(alpha: 0),
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
            color: context.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: context.colorScheme.outlineVariant),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total fare',
                      style: TextStyle(
                        color: context.colorScheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View fare calculation',
                      style: TextStyle(
                        color: context.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _currency(widget.totalFare),
                style: TextStyle(
                  color: context.colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
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
          style: IconButton.styleFrom(shape: const CircleBorder()),
          icon: Icon(
            LucideIcons.arrow_left,
            color: context.colorScheme.onSurface,
            size: 20,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.colorScheme.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                details,
                style: TextStyle(
                  color: context.colorScheme.onSurfaceVariant,
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
                : 'Book directly',
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
            color: context.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculated minimum',
                style: TextStyle(
                  color: context.colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _currency(minimumFare),
                style: TextStyle(
                  color: context.colorScheme.onSurface,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Divider(height: 28),
              Text(
                'Your offer',
                key: const ValueKey('custom-offer-label'),
                style: TextStyle(
                  color: context.colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
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
                  prefixText: '₱ ',
                  helperText: 'Enter a higher amount if you want to adjust it.',
                  errorText: widget.customFareError,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.colorScheme.outlineVariant,
                    ),
                  ),
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
            color: context.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Trip note (optional)',
                style: TextStyle(
                  color: context.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Share a concise pickup instruction when it helps.',
                style: TextStyle(
                  color: context.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
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
                  counterStyle: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.colorScheme.outlineVariant,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.colorScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: context.colorScheme.onSurface,
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

  Widget _buildFareDetailsContent(FareEstimate fareResult) {
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
    if (widget.isLoadingFare) return _buildLoadingContent();

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
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: context.colorScheme.onSurface.withValues(alpha: 0.12),
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
                  color: context.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AnimatedSize(
              duration: _viewTransitionDuration,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: _viewTransitionDuration,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, _) =>
                    ClipRect(child: currentChild ?? const SizedBox.shrink()),
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
