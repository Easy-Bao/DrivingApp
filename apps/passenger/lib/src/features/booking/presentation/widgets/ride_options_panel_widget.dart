import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/app/theme/app_theme.dart';
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
  this.isExpanded = false,
  this.scrollController,
  this.onPageBackPressed,
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
  final bool isExpanded;
  final ScrollController? scrollController;
  final VoidCallback? onPageBackPressed;

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
  static const _viewTransitionDuration = Duration(milliseconds: 260);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = widget.scrollController;
      if (!mounted || controller == null || !controller.hasClients) return;
      if (controller.offset > 0) controller.jumpTo(0);
    });
  }

  void _saveCustomOffer() {
    if (_hasValidFare) {
      _showView(_RideOptionsPanelView.summary);
    }
  }

  Widget _buildLoadingContent({bool showPrimaryAction = true}) {
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
          if (showPrimaryAction)
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

  Widget _buildPrimaryButton({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(key: key, onPressed: onPressed, child: Text(label)),
    );
  }

  Widget _buildSummaryPrimaryAction() {
    final fareResult = _fareResult;
    return _buildPrimaryButton(
      onPressed: _hasValidFare ? widget.onBookPressed : null,
      label: fareResult == null
          ? widget.isLoadingFare
                ? 'Calculating fare…'
                : 'Fare unavailable'
          : 'Book directly',
    );
  }

  Widget _buildCustomOfferPrimaryAction() {
    return _buildPrimaryButton(
      key: const ValueKey('custom-offer-save'),
      onPressed: _hasValidFare ? _saveCustomOffer : null,
      label: 'Save offer',
    );
  }

  Widget _buildTripNotePrimaryAction() {
    return _buildPrimaryButton(
      key: const ValueKey('trip-note-save'),
      onPressed: () => _showView(_RideOptionsPanelView.summary),
      label: 'Save note',
    );
  }

  Widget? _buildPinnedPrimaryAction() {
    if (!widget.isExpanded) return null;

    return switch (_currentView) {
      _RideOptionsPanelView.summary => _buildSummaryPrimaryAction(),
      _RideOptionsPanelView.customOffer when _minimumFare != null =>
        _buildCustomOfferPrimaryAction(),
      _RideOptionsPanelView.customOffer => _buildSummaryPrimaryAction(),
      _RideOptionsPanelView.tripNote => _buildTripNotePrimaryAction(),
      _RideOptionsPanelView.fareDetails => null,
    };
  }

  Widget _buildPanelHeader({required String title, required String details}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPanelBackButton(
          key: const ValueKey('panel-back'),
          onPressed: () => _showView(_RideOptionsPanelView.summary),
          tooltip: 'Back to trip summary',
        ),
        const SizedBox(width: 8),
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

  Widget _buildPanelBackButton({
    required Key key,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return HeroMode(
      enabled: widget.isExpanded,
      child: Hero(
        tag: 'ride-selection-back-button',
        child: IconButton(
          key: key,
          onPressed: onPressed,
          tooltip: tooltip,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          padding: EdgeInsets.zero,
          style: IconButton.styleFrom(shape: const CircleBorder()),
          icon: Icon(
            LucideIcons.arrow_left,
            color: context.colorScheme.onSurface,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSummaryHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanelBackButton(
            key: const ValueKey('panel-page-back'),
            onPressed:
                widget.onPageBackPressed ??
                () => _showView(_RideOptionsPanelView.summary),
            tooltip: 'Back to map',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trip details',
                  style: TextStyle(
                    color: context.colorScheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Review your ride before booking.',
                  style: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryContent({bool showPrimaryAction = true}) {
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
        if (widget.isExpanded) _buildExpandedSummaryHeader(),
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
        if (showPrimaryAction) _buildSummaryPrimaryAction(),
      ],
    );
  }

  Widget _buildCustomOfferContent({bool showPrimaryAction = true}) {
    final minimumFare = _minimumFare;
    if (minimumFare == null) {
      return _buildSummaryContent(showPrimaryAction: showPrimaryAction);
    }

    return Column(
      key: const ValueKey('custom-offer-content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPanelHeader(
          title: 'Set your offer',
          details: 'Match or raise the calculated fare.',
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Calculated minimum',
                style: TextStyle(
                  color: context.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      _currency(minimumFare),
                      style: TextStyle(
                        color: context.colorScheme.onSurface,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Minimum',
                      style: TextStyle(
                        color: context.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(height: 1, color: context.colorScheme.outlineVariant),
              const SizedBox(height: 16),
              Text(
                'Your offer',
                key: const ValueKey('custom-offer-label'),
                style: TextStyle(
                  color: context.colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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
                textInputAction: TextInputAction.done,
                onChanged: (value) {
                  widget.onCustomFareChanged(value);
                  setState(() {});
                },
                onSubmitted: (_) => _saveCustomOffer(),
                decoration: InputDecoration(
                  prefixText: '₱ ',
                  hintText: '0.00',
                  helperText: widget.customFareError == null
                      ? 'Match or raise the calculated fare.'
                      : null,
                  helperMaxLines: 2,
                  errorText: widget.customFareError,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (showPrimaryAction) _buildCustomOfferPrimaryAction(),
      ],
    );
  }

  Widget _buildTripNoteContent({bool showPrimaryAction = true}) {
    return Column(
      key: const ValueKey('trip-note-content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPanelHeader(
          title: 'Add a trip note',
          details: 'Help your driver find you quickly.',
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pickup note',
                style: TextStyle(
                  color: context.colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Optional · visible to your driver before pickup.',
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
                minLines: 4,
                maxLines: 5,
                maxLength: 160,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                onChanged: (value) {
                  widget.onNotesChanged(value);
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'For example: Meet me at the side entrance.',
                  contentPadding: const EdgeInsets.all(16),
                  alignLabelWithHint: true,
                  counterStyle: TextStyle(
                    color: context.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (showPrimaryAction) _buildTripNotePrimaryAction(),
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

  Widget _buildContent({bool showPrimaryAction = true}) {
    if (widget.isLoadingFare) {
      return _buildLoadingContent(showPrimaryAction: showPrimaryAction);
    }

    final fareResult = _fareResult;
    return switch (_currentView) {
      _RideOptionsPanelView.summary => _buildSummaryContent(
        showPrimaryAction: showPrimaryAction,
      ),
      _RideOptionsPanelView.customOffer => _buildCustomOfferContent(
        showPrimaryAction: showPrimaryAction,
      ),
      _RideOptionsPanelView.tripNote => _buildTripNoteContent(
        showPrimaryAction: showPrimaryAction,
      ),
      _RideOptionsPanelView.fareDetails when fareResult != null =>
        _buildFareDetailsContent(fareResult),
      _RideOptionsPanelView.fareDetails => _buildSummaryContent(
        showPrimaryAction: showPrimaryAction,
      ),
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
    final mediaPadding = MediaQuery.paddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final bottomInset = viewInsets.bottom > mediaPadding.bottom
        ? viewInsets.bottom
        : mediaPadding.bottom;
    final topPadding = widget.isExpanded ? mediaPadding.top + 8 : 12.0;
    final pinnedAction = _buildPinnedPrimaryAction();
    final isActionPinned = pinnedAction != null;
    return AnimatedContainer(
      duration: _viewTransitionDuration,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 16 + bottomInset),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: widget.isExpanded
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: widget.isExpanded
            ? const []
            : [
                BoxShadow(
                  color: context.colorScheme.onSurface.withValues(alpha: 0.12),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            controller: widget.scrollController,
            padding: EdgeInsets.only(bottom: isActionPinned ? 68 : 0),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isExpanded)
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
                    layoutBuilder: (currentChild, _) => ClipRect(
                      child: currentChild ?? const SizedBox.shrink(),
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
                    child: _buildContent(showPrimaryAction: !isActionPinned),
                  ),
                ),
              ],
            ),
          ),
          if (pinnedAction != null)
            Positioned(left: 0, right: 0, bottom: 0, child: pinnedAction),
        ],
      ),
    );
  }
}

@Preview(
  group: 'Trip selection',
  name: 'Interactive ride options panel',
  size: Size(390, 800),
)
Widget rideOptionsPanelPreview() {
  const fareResult = FareEstimate(
    baseFare: 20,
    distanceCharge: 5,
    timeCharge: 3.17,
    surgeCharge: 0,
    totalFare: 28.17,
  );

  return MaterialApp(
    theme: AppTheme.data,
    home: Scaffold(
      body: RideOptionsPanelWidget(
        passengerName: 'Avery Cruz',
        pickupLabel: 'Mountain View',
        destinationName: 'Near Bathroom',
        destinationAddress: 'Near Bathroom, 1600 Amphitheatre Pkwy, Mountain View, California 94043, United States',
        fareResult: fareResult,
        customFareController: TextEditingController(text: '28.17'),
        customFareError: null,
        isLoadingFare: false,
        fareError: null,
        onRetryFare: null,
        onCustomFareChanged: (_) {},
        notesController: TextEditingController(),
        onNotesChanged: (_) {},
        selectedTipAmount: 0,
        onTipSelected: (_) {},
        totalFare: fareResult.totalFare,
        onBookPressed: () {},
      ),
    ),
  );
}
