import 'package:design_system/design_system.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/booking.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_fare_details.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_options_loading_view.dart';
import 'package:passenger/src/features/booking/presentation/widgets/ride_options_sub_views.dart';

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
  String? _lastValidOfferText;

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

  void _showView(_RideOptionsView view) {
    if (view == _RideOptionsView.offer) {
      _lastValidOfferText = _hasValidFare
          ? widget.customFareController.text.trim()
          : _minimumFare?.toStringAsFixed(2);
    }
    setState(() => _currentView = view);
  }

  void _backToSummary() {
    if (_currentView == _RideOptionsView.offer && !_hasValidFare) {
      final fallback =
          _lastValidOfferText ?? _minimumFare?.toStringAsFixed(2) ?? '';
      if (fallback.isNotEmpty) {
        widget.customFareController.text = fallback;
        widget.onCustomFareChanged(fallback);
      }
    }
    FocusScope.of(context).unfocus();
    setState(() => _currentView = _RideOptionsView.summary);
  }

  Widget _buildFareStatus() {
    final error = widget.fareError;
    if (AppNetworkStatusScope.isUnavailableOf(context)) {
      return const RideOptionsLoadingView(showPrimaryAction: false);
    }
    if (error == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(child: Text('Fare details are unavailable.')),
      );
    }
    return RideFareStatusCard(error: error, onRetryFare: widget.onRetryFare);
  }

  Widget _buildActionButton({
    required Key key,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final colors = context.colorScheme;
    final radius = BorderRadius.circular(AppRadius.md);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: radius,
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? colors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
        ),
        child: Container(
          height: AppSize.minimumTouchTarget,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: isActive
                ? colors.primary.withValues(alpha: 0.05)
                : colors.surfaceContainerLowest,
            borderRadius: radius,
            border: Border.all(
              color: isActive ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textStyles.labelMedium?.tabular.copyWith(
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryView(BuildContext context) {
    final colors = context.colorScheme;
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
        RideSummaryTripCard(
          pickupLabel: widget.pickupLabel,
          destinationName: widget.destinationName,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (widget.requiresSignIn)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'Sign in or create an account to see your route and fare, then book a ride.',
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
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
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          ' · ',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Icon(
                          LucideIcons.banknote,
                          size: 14,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cash',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatPesoAmount(widget.totalFare),
                      key: const ValueKey('total-fare-amount'),
                      style: context.textStyles.headlineLarge?.tabular.copyWith(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                type: MaterialType.transparency,
                child: InkWell(
                  key: const ValueKey('fare-summary'),
                  onTap: _hasValidFare
                      ? () => _showView(_RideOptionsView.fareDetails)
                      : null,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  enableFeedback: false,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: WidgetStateProperty.resolveWith(
                    (states) => states.contains(WidgetState.focused)
                        ? colors.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 14,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Fare details',
                          style: context.textStyles.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(
                          LucideIcons.chevron_up,
                          size: 15,
                          color: colors.onSurface,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  key: const ValueKey('custom-offer-trigger'),
                  label: hasCustomOffer
                      ? 'Your offer: ${formatPesoAmount(enteredFare)}'
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
                      ? 'Tip: ${formatPesoAmount(widget.selectedTipAmount.toDouble())}'
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
          const SizedBox(height: AppSpacing.lg),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            key: const ValueKey('book-directly-button'),
            onPressed: widget.requiresSignIn || _hasValidFare
                ? widget.onBookPressed
                : null,
            style: rideOptionsPrimaryButtonStyle(context),
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
        final minimumFare = _minimumFare;
        if (minimumFare == null) return const SizedBox.shrink();
        return RideOfferSubView(
          minimumFare: minimumFare,
          enteredFare: _enteredFare,
          hasValidFare: _hasValidFare,
          customFareController: widget.customFareController,
          customFareError: widget.customFareError,
          onCustomFareChanged: (value) {
            widget.onCustomFareChanged(value);
            setState(() {});
          },
          onBackToSummary: _backToSummary,
        );
      case _RideOptionsView.tip:
        return RideTipSubView(
          selectedTipAmount: widget.selectedTipAmount,
          onTipSelected: (amount) {
            widget.onTipSelected(amount);
            setState(() {});
          },
          onBackToSummary: _backToSummary,
        );
      case _RideOptionsView.note:
        return RideNoteSubView(
          notesController: widget.notesController,
          onNotesChanged: (value) {
            widget.onNotesChanged(value);
            setState(() {});
          },
          onBackToSummary: _backToSummary,
        );
      case _RideOptionsView.fareDetails:
        final fareResult = _fareResult;
        if (fareResult == null) return const SizedBox.shrink();
        return RideFareDetails(
          passengerName: widget.passengerName,
          fareResult: fareResult,
          offeredFare: _enteredFare ?? fareResult.totalFare,
          tipAmount: widget.selectedTipAmount,
          totalFare: widget.totalFare,
          onBackPressed: _backToSummary,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoadingFare && !widget.requiresSignIn) {
      return const RideOptionsLoadingView(showPrimaryAction: true);
    }

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 240);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxScrollHeight =
        (screenHeight -
                MediaQuery.viewInsetsOf(context).bottom -
                MediaQuery.paddingOf(context).vertical -
                80)
            .clamp(0.0, screenHeight * 0.72);

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
          color: context.colorScheme.surfaceContainerLowest,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
          border: Border(
            top: BorderSide(color: context.colorScheme.outlineVariant),
          ),
          boxShadow: [
            BoxShadow(
              color: context.colorScheme.onSurface.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -6),
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
                      child: ConstrainedBox(
                        key: ValueKey(_currentView),
                        constraints: BoxConstraints(maxHeight: maxScrollHeight),
                        child: SingleChildScrollView(
                          controller: _currentView == _RideOptionsView.summary
                              ? widget.scrollController
                              : null,
                          physics: const ClampingScrollPhysics(),
                          child: _buildCurrentView(context),
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
    );
  }
}

@Preview(
  group: 'Trip selection',
  name: 'Interactive ride options panel',
  size: Size(390, 800),
)
Widget rideOptionsPanelPreview() => const _RideOptionsPanelPreviewHost();

class _RideOptionsPanelPreviewHost extends StatefulWidget {
  const _RideOptionsPanelPreviewHost();

  @override
  State<_RideOptionsPanelPreviewHost> createState() =>
      _RideOptionsPanelPreviewHostState();
}

class _RideOptionsPanelPreviewHostState
    extends State<_RideOptionsPanelPreviewHost> {
  static const _fareResult = FareEstimate(
    baseFare: 20,
    distanceCharge: 5,
    timeCharge: 3.17,
    surgeCharge: 0,
    totalFare: 28.17,
  );

  final TextEditingController _customFareController = TextEditingController(
    text: '28.17',
  );
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _customFareController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.main,
      home: Scaffold(
        body: RideOptionsPanel(
          passengerName: 'Avery Cruz',
          pickupLabel: 'Mountain View',
          destinationName: 'Near Bathroom',
          destinationAddress: 'Near Bathroom, 1600 Amphitheatre Pkwy, Mountain View, California 94043, United States',
          fareResult: _fareResult,
          customFareController: _customFareController,
          customFareError: null,
          isLoadingFare: false,
          fareError: null,
          onRetryFare: null,
          onCustomFareChanged: (_) {},
          notesController: _notesController,
          onNotesChanged: (_) {},
          selectedTipAmount: 0,
          onTipSelected: (_) {},
          totalFare: _fareResult.totalFare,
          onBookPressed: () {},
        ),
      ),
    );
  }
}
