import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:passenger/src/features/ride_history/presentation/bloc/ride_details/ride_details_cubit.dart';

class const RideRatingPrompt({
  super.key,
  required this.driverId,
  required this.driverName,
  required this.rideId,
  required this.cubit,
  required this.onDone,
  this.initiallyExpanded = false,
}) extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String rideId;
  final RideDetailsCubit cubit;
  final VoidCallback onDone;
  final bool initiallyExpanded;

  @override
  State<RideRatingPrompt> createState() => _RideRatingPromptState();
}

class _RideRatingPromptState extends State<RideRatingPrompt> {
  final _feedbackController = TextEditingController();
  int _rating = 0;
  late bool _isExpanded;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submit() {
    final state = widget.cubit.state;
    if (state.isSubmittingReview || state.isLoadingReview) return;
    if (_rating == 0) {
      setState(
        () => _validationError = 'Choose a star rating before submitting.',
      );
      return;
    }
    unawaited(
      widget.cubit.submitRating(
        driverId: widget.driverId,
        rideId: widget.rideId,
        rating: _rating,
        comment: _feedbackController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RideDetailsCubit, RideDetailsState>(
      bloc: widget.cubit,
      builder: (context, state) {
        final colors = context.colorScheme;
        final submittedReview = state.submittedReview;
        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                submittedReview == null
                    ? 'How was your ride with ${widget.driverName}?'
                    : 'You rated this ride ${submittedReview.rating.toStringAsFixed(0)} stars',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (state.isLoadingReview) ...[
                const SizedBox(height: AppSpacing.md),
                const Center(child: CircularProgressIndicator()),
              ] else if (state.reviewErrorMessage != null &&
                  submittedReview == null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.reviewErrorMessage!,
                  style: TextStyle(color: colors.error),
                ),
                TextButton(
                  onPressed: () =>
                      unawaited(widget.cubit.loadMyReview(widget.rideId)),
                  child: const Text('Try again'),
                ),
                TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Not now'),
                ),
              ] else if (submittedReview != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _RatingStars(
                  value: submittedReview.rating.round(),
                  enabled: false,
                ),
                if (submittedReview.comment.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    submittedReview.comment,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                ],
              ] else if (!_isExpanded) ...[
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton(
                  onPressed: () => setState(() => _isExpanded = true),
                  child: const Text('Rate this ride'),
                ),
              ] else ...[
                const SizedBox(height: AppSpacing.xs),
                _RatingStars(
                  value: _rating,
                  enabled: !state.isSubmittingReview,
                  onChanged: (value) => setState(() {
                    _rating = value;
                    _validationError = null;
                  }),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextField(
                  controller: _feedbackController,
                  enabled: !state.isSubmittingReview,
                  maxLength: 500,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Comment (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (_validationError != null ||
                    state.ratingErrorMessage != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _validationError ?? state.ratingErrorMessage!,
                    style: TextStyle(color: colors.error),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                FilledButton(
                  onPressed: state.isSubmittingReview ? null : _submit,
                  child: state.isSubmittingReview
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit rating'),
                ),
                TextButton(
                  onPressed: state.isSubmittingReview ? null : widget.onDone,
                  child: const Text('Not now'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class const _RatingStars({
  required this.value,
  required this.enabled,
  this.onChanged,
}) extends StatelessWidget {
  final int value;
  final bool enabled;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var star = 1; star <= 5; star++)
          IconButton(
            tooltip: '$star star${star == 1 ? '' : 's'}',
            constraints: const BoxConstraints(
              minWidth: AppSize.minimumTouchTarget,
              minHeight: AppSize.minimumTouchTarget,
            ),
            onPressed: enabled ? () => onChanged?.call(star) : null,
            icon: Icon(
              star <= value ? Icons.star_rounded : Icons.star_outline,
              color: star <= value
                  ? context.semanticColors.rating
                  : context.colorScheme.outline,
              size: 30,
            ),
          ),
      ],
    );
  }
}
