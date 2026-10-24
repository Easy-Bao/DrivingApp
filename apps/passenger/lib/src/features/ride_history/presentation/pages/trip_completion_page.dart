import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
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
            state.reviewErrorMessage == null;
        final busy = state.isSubmittingReview;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !busy) _leave();
          },
          child: Scaffold(
            backgroundColor: colors.surface,
            appBar: AppBar(
              backgroundColor: colors.surface,
              scrolledUnderElevation: 0,
              leading: IconButton(
                tooltip: 'Close',
                onPressed: busy ? null : _leave,
                icon: const Icon(Icons.close),
              ),
              title: const Text('Ride completed'),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'How was your ride?',
                      textAlign: TextAlign.center,
                      style: context.textStyles.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    Center(
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: colors.surfaceContainerHighest,
                        foregroundColor: colors.onSurface,
                        child: const Icon(Icons.person_outline, size: 32),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      ride.displayDriverName,
                      textAlign: TextAlign.center,
                      style: context.textStyles.titleMedium,
                    ),
                    if (canRate) ...[
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var star = 1; star <= 5; star++)
                            IconButton(
                              tooltip: '$star star${star == 1 ? '' : 's'}',
                              onPressed: reviewReady && !busy && review == null
                                  ? () => setState(() => _rating = star)
                                  : null,
                              icon: Icon(
                                star <= (review?.rating.round() ?? _rating)
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 34,
                                color:
                                    star <= (review?.rating.round() ?? _rating)
                                    ? context.semanticColors.rating
                                    : colors.outlineVariant,
                              ),
                            ),
                        ],
                      ),
                      if (state.isLoading || state.isLoadingReview)
                        const Center(
                          child: CircularProgressIndicator.adaptive(),
                        )
                      else if (state.reviewErrorMessage != null) ...[
                        Text(
                          state.reviewErrorMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.error),
                        ),
                        TextButton(
                          onPressed: () =>
                              widget.detailsCubit.loadMyReview(ride.id),
                          child: const Text('Try again'),
                        ),
                      ] else if (review != null)
                        Text(
                          'Thank you for your feedback',
                          textAlign: TextAlign.center,
                          style: context.textStyles.bodyMedium,
                        )
                      else if (_rating > 0) ...[
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
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ],
                      if (state.ratingErrorMessage != null)
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            state.ratingErrorMessage!,
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                    ],
                    const SizedBox(height: AppSpacing.xxl),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.outlineVariant),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(child: Text('Total')),
                              Text(
                                ride.farePesos == null
                                    ? 'Unavailable'
                                    : formatPesoAmount(ride.farePesos!),
                                style: context.textStyles.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          const Divider(height: 1),
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
                            child: const Text('View receipt'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: FilledButton(
                  onPressed:
                      busy || (_rating > 0 && review == null && !reviewReady)
                      ? null
                      : _done,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(AppSize.controlHeight),
                    shape: const StadiumBorder(),
                  ),
                  child: busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
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
