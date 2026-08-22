import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';

class PassengerRatingPage extends StatefulWidget {
  final String driverId;
  final String driverName;
  final String rideId;

  const PassengerRatingPage({
    super.key,
    required this.driverId,
    required this.driverName,
    required this.rideId,
  });

  @override
  State<PassengerRatingPage> createState() => _PassengerRatingPageState();
}

class _PassengerRatingPageState extends State<PassengerRatingPage> {
  int _selectedStars = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  Future<void> _submitRating() async {
    if (_selectedStars == 0) {
      setState(() => _error = 'Choose a star rating before submitting.');
      return;
    }
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final submitted = await Modular.get<BiddingRemoteDataSource>()
          .submitDriverReview(
            driverId: widget.driverId,
            rideId: widget.rideId,
            rating: _selectedStars.toDouble(),
            comment: _feedbackController.text.trim(),
          );
      if (!submitted) throw StateError('review was not accepted');
      if (mounted) context.goNamed(HomeRoutes.home);
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to submit your rating. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverName = widget.driverName.trim().isEmpty
        ? 'Your driver'
        : widget.driverName.trim();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: AppTheme.warning,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Step 2 of 2',
                      style: TextStyle(
                        color: AppTheme.tertiaryColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Rate $driverName',
                      key: const ValueKey('rating-driver-name'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'How was your ride with $driverName?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.tertiaryColor,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.borderSide),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: const BoxDecoration(
                              color: AppTheme.secondaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.user_round,
                              size: 18,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driverName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                const Text(
                                  'Driver for This Trip',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.tertiaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Rate Your Experience',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final isSelected = index < _selectedStars;
                        return Material(
                          color: AppTheme.surface.withValues(alpha: 0),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => setState(() {
                              _selectedStars = index + 1;
                              _error = null;
                            }),
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                isSelected ? Icons.star : Icons.star_border,
                                size: 30,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.borderSide,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      height: 116,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.borderSide),
                      ),
                      child: TextField(
                        controller: _feedbackController,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Leave feedback (optional)',
                          isDense: true,
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          contentPadding: EdgeInsets.only(top: 14),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppTheme.cancel,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitRating,
                  style: ElevatedButton.styleFrom(shape: const StadiumBorder()),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.surface,
                          ),
                        )
                      : const Text('Submit Rating'),
                ),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => context.goNamed(HomeRoutes.home),
                child: const Text('Skip for Now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
