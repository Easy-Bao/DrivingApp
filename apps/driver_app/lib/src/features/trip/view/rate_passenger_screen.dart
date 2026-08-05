import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/home/home_routes.dart';
import 'package:driver_app/src/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class RatePassengerScreen extends StatefulWidget {
  final String rideId;
  final String passengerId;
  final String passengerName;

  const RatePassengerScreen({
    super.key,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
  });

  @override
  State<RatePassengerScreen> createState() => _RatePassengerScreenState();
}

class _RatePassengerScreenState extends State<RatePassengerScreen> {
  final _commentController = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_rating == 0 || _isSubmitting) return;
    if (widget.rideId.isEmpty || widget.passengerId.isEmpty) {
      setState(() => _error = 'Passenger trip details are unavailable.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final submitted = await Modular.get<TripRemoteDataSource>()
          .submitPassengerReview(
            passengerId: widget.passengerId,
            rideId: widget.rideId,
            rating: _rating.toDouble(),
            comment: _commentController.text.trim(),
          );
      if (!submitted) throw StateError('review was not accepted');
      if (mounted) context.goNamed(HomeRoutes.dashboard);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = 'Unable to submit the rating. Please try again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppTheme.borderSide, width: 2),
                ),
                child: const Icon(
                  LucideIcons.user,
                  color: AppTheme.primaryColor,
                  size: 38,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Rate Your Passenger',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.passengerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.tertiaryColor,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () => setState(() => _rating = index + 1),
                    icon: Icon(
                      LucideIcons.star,
                      color: index < _rating
                          ? Colors.amber
                          : AppTheme.borderSide,
                      size: 38,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _commentController,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add a comment (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.cancel,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              GestureDetector(
                onTap: _rating > 0 && !_isSubmitting ? _submit : null,
                child: Container(
                  width: double.infinity,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _rating > 0 && !_isSubmitting
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit Rating',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => context.goNamed(HomeRoutes.dashboard),
                child: const Text('Skip for now'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
