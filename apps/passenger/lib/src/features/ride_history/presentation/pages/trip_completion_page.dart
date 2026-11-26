import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_details/ride_details_cubit.dart';
import 'package:passenger/src/features/ride_history/ride_history_routes.dart';

class TripCompletionPage extends StatefulWidget {
  const TripCompletionPage({
    super.key,
    required this.ride,
    required this.detailsCubit,
    this.returnToReceipt = false,
  });

  final RideSnapshot ride;
  final RideDetailsCubit detailsCubit;
  final bool returnToReceipt;

  @override
  State<TripCompletionPage> createState() => _TripCompletionPageState();
}

class _TripCompletionPageState extends State<TripCompletionPage> {
  final _commentController = TextEditingController();
  int _rating = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_loadReview());
  }

  Future<void> _loadReview() async {
    await widget.detailsCubit.load(widget.ride.id);
    if (!mounted) return;
    await widget.detailsCubit.loadMyReview(widget.ride.id);
  }

  void _leave() {
    if (widget.returnToReceipt) {
      context.pop();
    } else {
      context.goNamed(HomeRoutes.home);
    }
  }

  Future<void> _done() async {
    final cubit = widget.detailsCubit;
    if (cubit.state.isSubmittingReview) return;
    final ride = cubit.state.ride ?? widget.ride;
    if (_rating > 0 && cubit.state.submittedReview == null) {
      final driverId = ride.driverId;
      if (driverId == null ||
          driverId.isEmpty ||
          cubit.state.isLoading ||
          cubit.state.isLoadingReview ||
          !cubit.state.hasLoadedReview ||
          cubit.state.reviewErrorMessage != null) {
        return;
      }
      await cubit.submitRating(
        driverId: driverId,
        rideId: ride.id,
        rating: _rating,
        comment: _commentController.text.trim(),
      );
      if (!mounted || cubit.state.submittedReview == null) return;
    }
    if (mounted) _leave();
  }

  @override
  void dispose() {
    _commentController.dispose();
    unawaited(widget.detailsCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideDetailsCubit, RideDetailsState>(
      bloc: widget.detailsCubit,
      builder: (context, state) {
        final ride = state.ride ?? widget.ride;
        final colors = context.colorScheme;
        final review = state.submittedReview;
        final canRate =
            ride.status == 'completed' && ride.driverId?.isNotEmpty == true;
        final reviewReady =
            !state.isLoading &&
            !state.isLoadingReview &&
            state.hasLoadedReview &&
            state.reviewErrorMessage == null;
        final busy = state.isSubmittingReview;
        final horizontalPadding = MediaQuery.sizeOf(context).width < 360
            ? AppLayout.pagePadding
            : AppLayout.pagePaddingWide;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !busy) _leave();
          },
          child: Scaffold(
            backgroundColor: context.canvasColor,
            appBar: AppBar(
              backgroundColor: context.canvasColor,
              surfaceTintColor: Colors.transparent,
              scrolledUnderElevation: 0,
              leading: IconButton(
                tooltip: 'Close',
                onPressed: busy ? null : _leave,
                style:
                    IconButton.styleFrom(
                      foregroundColor: colors.onSurface,
                      enableFeedback: false,
                      splashFactory: NoSplash.splashFactory,
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.focused)
                            ? colors.primary.withValues(alpha: 0.12)
                            : Colors.transparent,
                      ),
                    ),
                icon: const Icon(LucideIcons.x, size: 20),
              ),
              title: Text(
                'Ride completed',
                style: context.textStyles.titleMedium?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppLayout.pageMaxWidth,
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      AppSpacing.xl,
                      horizontalPadding,
                      AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerLowest,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.outlineVariant),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              LucideIcons.user,
                              size: 26,
                              color: colors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'How was your ride?',
                          textAlign: TextAlign.center,
                          style: context.textStyles.headlineSmall?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          ride.displayDriverName,
                          textAlign: TextAlign.center,
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        if (canRate) ...[
                          const SizedBox(height: AppSpacing.xl),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var star = 1; star <= 5; star++)
                                IconButton(
                                  tooltip: '$star star${star == 1 ? '' : 's'}',
                                  style:
                                      IconButton.styleFrom(
                                        enableFeedback: false,
                                        splashFactory: NoSplash.splashFactory,
                                      ).copyWith(
                                        overlayColor:
                                            WidgetStateProperty.resolveWith(
                                              (states) =>
                                                  states.contains(
                                                    WidgetState.focused,
                                                  )
                                                  ? colors.primary.withValues(
                                                      alpha: 0.12,
                                                    )
                                                  : Colors.transparent,
                                            ),
                                      ),
                                  onPressed:
                                      reviewReady && !busy && review == null
                                      ? () => setState(() => _rating = star)
                                      : null,
                                  icon: Icon(
                                    star <= (review?.rating.round() ?? _rating)
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 34,
                                    color:
                                        star <=
                                            (review?.rating.round() ?? _rating)
                                        ? context.semanticColors.rating
                                        : colors.outlineVariant,
                                  ),
                                ),
                            ],
                          ),
                          if (state.isLoading ||
                              state.isLoadingReview ||
                              (!state.hasLoadedReview &&
                                  state.reviewErrorMessage == null))
                            const Padding(
                              padding: EdgeInsets.only(top: AppSpacing.sm),
                              child: Center(
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            )
                          else if (state.reviewErrorMessage
                              case final reviewErrorMessage?) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              reviewErrorMessage,
                              textAlign: TextAlign.center,
                              style: context.textStyles.bodySmall?.copyWith(
                                color: colors.error,
                              ),
                            ),
                            TextButton(
                              onPressed: () => widget.detailsCubit.loadMyReview(
                                ride.id,
                                refresh: true,
                              ),
                              style:
                                  TextButton.styleFrom(
                                    foregroundColor: colors.onSurface,
                                    enableFeedback: false,
                                    splashFactory: NoSplash.splashFactory,
                                  ).copyWith(
                                    overlayColor:
                                        WidgetStateProperty.resolveWith(
                                          (states) =>
                                              states.contains(
                                                WidgetState.focused,
                                              )
                                              ? colors.primary.withValues(
                                                  alpha: 0.12,
                                                )
                                              : Colors.transparent,
                                        ),
                                  ),
                              child: const Text('Try again'),
                            ),
                          ] else if (review != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Thank you for your feedback',
                              textAlign: TextAlign.center,
                              style: context.textStyles.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ] else if (_rating > 0) ...[
                            const SizedBox(height: AppSpacing.lg),
                            TextField(
                              controller: _commentController,
                              enabled: !busy,
                              minLines: 2,
                              maxLines: 4,
                              maxLength: 500,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: 'Comment (optional)',
                                hintText: _rating <= 3
                                    ? 'What could have been better?'
                                    : 'What went well?',
                                filled: true,
                                fillColor: colors.surfaceContainerLowest,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  borderSide: BorderSide(
                                    color: colors.outlineVariant,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  borderSide: BorderSide(
                                    color: colors.outlineVariant,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  borderSide: BorderSide(color: colors.primary),
                                ),
                              ),
                            ),
                          ],
                          if (state.ratingErrorMessage
                              case final ratingErrorMessage?) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                ratingErrorMessage,
                                textAlign: TextAlign.center,
                                style: context.textStyles.bodySmall?.copyWith(
                                  color: colors.error,
                                ),
                              ),
                            ),
                          ],
                        ],
                        const SizedBox(height: AppSpacing.xxl),
                        Container(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.lg,
                            AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerLowest,
                            border: Border.all(color: colors.outlineVariant),
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Total',
                                      style: context.textStyles.bodyMedium
                                          ?.copyWith(
                                            color: colors.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Flexible(
                                    child: Text(
                                      switch (ride.farePesos) {
                                        final farePesos? => formatPesoAmount(
                                          farePesos,
                                        ),
                                        null => 'Unavailable',
                                      },
                                      textAlign: TextAlign.end,
                                      style: context
                                          .textStyles
                                          .titleMedium
                                          ?.tabular
                                          .copyWith(
                                            color: colors.onSurface,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Divider(
                                height: 1,
                                color: colors.outlineVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                              TextButton(
                                onPressed: busy
                                    ? null
                                    : () => context.pushNamed(
                                        RideHistoryRoutes.rideDetails,
                                        extra: (
                                          ride: ride,
                                          showRatingAction: false,
                                        ),
                                      ),
                                style:
                                    TextButton.styleFrom(
                                      foregroundColor: colors.onSurface,
                                      enableFeedback: false,
                                      splashFactory: NoSplash.splashFactory,
                                      minimumSize: const Size(
                                        double.infinity,
                                        AppSize.minimumTouchTarget,
                                      ),
                                    ).copyWith(
                                      overlayColor:
                                          WidgetStateProperty.resolveWith(
                                            (states) =>
                                                states.contains(
                                                  WidgetState.focused,
                                                )
                                                ? colors.primary.withValues(
                                                    alpha: 0.08,
                                                  )
                                                : Colors.transparent,
                                          ),
                                    ),
                                child: const Text('View receipt'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  AppSpacing.md,
                  horizontalPadding,
                  AppSpacing.lg,
                ),
                child: FilledButton(
                  onPressed:
                      busy || (_rating > 0 && review == null && !reviewReady)
                      ? null
                      : _done,
                  style:
                      FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        elevation: 0,
                        enableFeedback: false,
                        splashFactory: NoSplash.splashFactory,
                        minimumSize: const Size.fromHeight(
                          AppSize.controlHeight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        textStyle: context.textStyles.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ).copyWith(
                        overlayColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.focused)
                              ? colors.onPrimary.withValues(alpha: 0.16)
                              : Colors.transparent,
                        ),
                      ),
                  child: busy
                      ? SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onPrimary,
                          ),
                        )
                      : const Text('Done'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
