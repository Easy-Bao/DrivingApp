import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_fare_details.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_options_loading_view.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_panel_header.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_tip_selector.dart';

enum _RideOptionsView { summary, offer, tip, note, fareDetails }

class RideOptionsPanel extends StatefulWidget {
  const RideOptionsPanel({
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
    this.requiresSignIn = false,
    this.scrollController,
    this.onPageBackPressed,
  });

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
  final bool requiresSignIn;
  final ScrollController? scrollController;
  final VoidCallback? onPageBackPressed;

  @override
  State<RideOptionsPanel> createState() => _RideOptionsPanelState();
}

class _RideOptionsPanelState extends State<RideOptionsPanel> {
  _RideOptionsView _currentView = _RideOptionsView.summary;

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

  void _showView(_RideOptionsView view) {
    setState(() {
      _currentView = view;
    });
  }

  void _backToSummary() {
    FocusScope.of(context).unfocus();
    setState(() {
      _currentView = _RideOptionsView.summary;
    });
  }

  Widget _buildOfferView(BuildContext context) {
    final minimumFare = _minimumFare;
    if (minimumFare == null) return const SizedBox.shrink();

    return ConstrainedBox(
      key: const ValueKey(_RideOptionsView.offer),
      constraints: BoxConstraints(
        maxHeight:
            (MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).bottom -
                    MediaQuery.paddingOf(context).vertical -
                    80)
                .clamp(0.0, MediaQuery.sizeOf(context).height * 0.72),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RidePanelHeader(
              closeKey: const ValueKey('panel-back'),
              onClose: _backToSummary,
              title: 'Set your offer',
              details: 'Match or raise the calculated fare.',
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: context.colorScheme.outlineVariant,
                  width: 0.8,
                ),
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
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: context.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
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
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    textInputAction: TextInputAction.done,
                    onChanged: (value) {
                      widget.onCustomFareChanged(value);
                      setState(() {});
                    },
                    onSubmitted: (_) {
                      if (_hasValidFare) {
                        _backToSummary();
                      }
                    },
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: context.colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    decoration: InputDecoration(
                      prefixText: '₱ ',
                      hintText: '0.00',
                      helperText: widget.customFareError == null
                          ? 'Match or raise the calculated fare.'
                          : null,
                      helperMaxLines: 2,
                      errorText: widget.customFareError,
                      errorMaxLines: 3,
                      errorStyle: TextStyle(
                        color: context.colorScheme.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final increment in const [10, 20, 50])
                        ActionChip(
                          label: Text('+₱$increment'),
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          onPressed: () {
                            final current = _enteredFare ?? minimumFare;
                            widget.customFareController.text =
                                (current + increment).toStringAsFixed(2);
                            widget.onCustomFareChanged(
                              widget.customFareController.text,
                            );
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                key: const ValueKey('custom-offer-save'),
                onPressed: _hasValidFare ? _backToSummary : null,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colorScheme.onSurface,
                  foregroundColor: context.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Save offer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipView(BuildContext context) {
    return ConstrainedBox(
      key: const ValueKey(_RideOptionsView.tip),
      constraints: BoxConstraints(
        maxHeight:
            (MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).bottom -
                    MediaQuery.paddingOf(context).vertical -
                    80)
                .clamp(0.0, MediaQuery.sizeOf(context).height * 0.72),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RidePanelHeader(
              closeKey: const ValueKey('panel-back'),
              onClose: _backToSummary,
              title: 'Tip your driver',
              details: '100% of your tip goes directly to the driver.',
            ),
            const SizedBox(height: 16),
            RideTipSelector(
              selectedTipAmount: widget.selectedTipAmount,
              onTipSelected: (amount) {
                widget.onTipSelected(amount);
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                key: const ValueKey('tip-save-button'),
                onPressed: _backToSummary,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colorScheme.onSurface,
                  foregroundColor: context.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteView(BuildContext context) {
    return ConstrainedBox(
      key: const ValueKey(_RideOptionsView.note),
      constraints: BoxConstraints(
        maxHeight:
            (MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).bottom -
                    MediaQuery.paddingOf(context).vertical -
                    80)
                .clamp(0.0, MediaQuery.sizeOf(context).height * 0.72),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RidePanelHeader(
              closeKey: const ValueKey('panel-back'),
              onClose: _backToSummary,
              title: 'Add a trip note',
              details: 'Help your driver find you quickly.',
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.file_text,
                        size: 18,
                        color: context.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Pickup note',
                        style: TextStyle(
                          color: context.colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
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
                    minLines: 3,
                    maxLines: 5,
                    maxLength: 160,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    inputFormatters: [LengthLimitingTextInputFormatter(160)],
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.newline,
                    onChanged: (value) {
                      widget.onNotesChanged(value);
                      setState(() {});
                    },
                    decoration: InputDecoration(
                      hintText: 'For example: Meet me at the side entrance.',
                      contentPadding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                      alignLabelWithHint: true,
                      counterStyle: TextStyle(
                        color: context.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final preset in const [
                        'Wait at lobby',
                        'Near entrance',
                        'Have luggage',
                        'Call on arrival',
                      ])
                        ActionChip(
                          label: Text(preset),
                          materialTapTargetSize: MaterialTapTargetSize.padded,
                          onPressed: () {
                            final current = widget.notesController.text.trim();
                            final next = current.isEmpty
                                ? preset
                                : current.contains(preset)
                                ? current
                                : '$current. $preset';
                            final clamped = next.length > 160
                                ? next.substring(0, 160)
                                : next;
                            widget.notesController.text = clamped;
                            widget.onNotesChanged(widget.notesController.text);
                            setState(() {});
                          },
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                key: const ValueKey('trip-note-save'),
                onPressed: _backToSummary,
                style: FilledButton.styleFrom(
                  backgroundColor: context.colorScheme.onSurface,
                  foregroundColor: context.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Save note'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareDetailsView(BuildContext context) {
    final fareResult = _fareResult;
    if (fareResult == null) return const SizedBox.shrink();

    return ConstrainedBox(
      key: const ValueKey(_RideOptionsView.fareDetails),
      constraints: BoxConstraints(
        maxHeight:
            (MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).bottom -
                    MediaQuery.paddingOf(context).vertical -
                    80)
                .clamp(0.0, MediaQuery.sizeOf(context).height * 0.72),
      ),
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: RideFareDetails(
          passengerName: widget.passengerName,
          fareResult: fareResult,
          offeredFare: _enteredFare ?? fareResult.totalFare,
          tipAmount: widget.selectedTipAmount,
          totalFare: widget.totalFare,
          onBackPressed: _backToSummary,
        ),
      ),
    );
  }

  Widget _buildLoadingContent({bool showPrimaryAction = true}) {
    return RideOptionsLoadingView(showPrimaryAction: showPrimaryAction);
  }

  Widget _buildFareStatus() {
    final error = widget.fareError;
    if (AppNetworkStatusScope.isUnavailableOf(context)) {
      return _buildLoadingContent(showPrimaryAction: false);
    }
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
        borderRadius: BorderRadius.circular(AppRadius.lg),
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

  Widget _buildActionButton({
    required Key key,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isActive
                ? context.colorScheme.surfaceContainerHighest
                : context.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isActive
                  ? context.colorScheme.primary.withValues(alpha: 0.5)
                  : context.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryView(BuildContext context) {
    final fareResult = _fareResult;
    final enteredFare = _enteredFare;
    final minimumFare = _minimumFare;
    final hasCustomOffer =
        minimumFare != null && enteredFare != null && enteredFare > minimumFare;
    final note = widget.notesController.text.trim();

    return Column(
      key: const ValueKey(_RideOptionsView.summary),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const ValueKey('trip-summary-card'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: context.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.5,
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Column(
                children: [
                  const RouteStopMarker(isPickup: true, size: 18),
                  CustomPaint(
                    size: const Size(2, 22),
                    painter: _DottedLinePainter(
                      color: context.colorScheme.outlineVariant,
                    ),
                  ),
                  const RouteStopMarker(isPickup: false, size: 18),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pick up',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.pickupLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Drop off',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.destinationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (widget.requiresSignIn)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Sign in or create an account to see your route and fare, then book a ride.',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else if (fareResult == null)
          _buildFareStatus()
        else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Total fare',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          ' · ',
                          style: TextStyle(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Icon(
                          LucideIcons.banknote,
                          size: 14,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cash',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currency(widget.totalFare),
                      key: const ValueKey('total-fare-amount'),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: context.colorScheme.onSurface,
                        letterSpacing: -0.8,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                key: const ValueKey('fare-summary'),
                onTap: _hasValidFare
                    ? () => _showView(_RideOptionsView.fareDetails)
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 14,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Fare details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: context.colorScheme.onSurface,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.chevron_up,
                        size: 16,
                        color: context.colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  key: const ValueKey('custom-offer-trigger'),
                  label: hasCustomOffer
                      ? 'Your offer: ${_currency(enteredFare)}'
                      : 'Offer',
                  isActive: hasCustomOffer,
                  onTap: () => _showView(_RideOptionsView.offer),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  key: const ValueKey('tip-trigger'),
                  label: widget.selectedTipAmount > 0
                      ? 'Tip: ${_currency(widget.selectedTipAmount.toDouble())}'
                      : 'Tip',
                  isActive: widget.selectedTipAmount > 0,
                  onTap: () => _showView(_RideOptionsView.tip),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildActionButton(
                  key: const ValueKey('trip-note-trigger'),
                  label: note.isNotEmpty ? 'Note added' : 'Note',
                  isActive: note.isNotEmpty,
                  onTap: () => _showView(_RideOptionsView.note),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            key: const ValueKey('book-directly-button'),
            onPressed: widget.requiresSignIn || _hasValidFare
                ? widget.onBookPressed
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: context.colorScheme.onSurface,
              foregroundColor: context.colorScheme.surface,
              disabledBackgroundColor:
                  context.colorScheme.surfaceContainerHighest,
              disabledForegroundColor: context.colorScheme.onSurfaceVariant
                  .withValues(alpha: 0.45),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            child: Text(
              widget.requiresSignIn
                  ? 'Sign in to book'
                  : fareResult == null
                  ? widget.isLoadingFare
                        ? 'Calculating fare…'
                        : 'Fare unavailable'
                  : 'Choose driver',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentView(BuildContext context) {
    switch (_currentView) {
      case _RideOptionsView.summary:
        return _buildSummaryView(context);
      case _RideOptionsView.offer:
        return _buildOfferView(context);
      case _RideOptionsView.tip:
        return _buildTipView(context);
      case _RideOptionsView.note:
        return _buildNoteView(context);
      case _RideOptionsView.fareDetails:
        return _buildFareDetailsView(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoadingFare && !widget.requiresSignIn) {
      return _buildLoadingContent(showPrimaryAction: true);
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 240);

    return PopScope(
      canPop: _currentView == _RideOptionsView.summary,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _backToSummary();
        }
      },
      child: Container(
        key: const ValueKey('ride-options-panel'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.onSurface.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: context.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Flexible(
                  child: AnimatedSize(
                    duration: duration,
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.topCenter,
                    child: AnimatedSwitcher(
                      duration: duration,
                      reverseDuration: reduceMotion
                          ? Duration.zero
                          : const Duration(milliseconds: 160),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.topCenter,
                          clipBehavior: Clip.hardEdge,
                          children: [
                            // Outgoing content must not hold the sheet open.
                            for (final child in previousChildren)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: ExcludeSemantics(
                                    child: ClipRect(
                                      child: OverflowBox(
                                        alignment: Alignment.topCenter,
                                        minHeight: 0,
                                        maxHeight: double.infinity,
                                        child: child,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ?currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        final isSummary =
                            child.key ==
                            const ValueKey(_RideOptionsView.summary);
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: reduceMotion || isSummary
                                ? Offset.zero
                                : const Offset(0, 0.08),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: SingleChildScrollView(
                        key: ValueKey(_currentView),
                        physics: const ClampingScrollPhysics(),
                        child: _buildCurrentView(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  final Color color;

  const _DottedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    double startY = 3.0;
    while (startY < size.height - 3.0) {
      canvas.drawCircle(Offset(size.width / 2, startY), 1.0, paint);
      startY += 5.0;
    }
  }

  @override
  bool shouldRepaint(covariant _DottedLinePainter oldDelegate) =>
      color != oldDelegate.color;
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
    theme: AppTheme.main,
    home: Scaffold(
      body: RideOptionsPanel(
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
