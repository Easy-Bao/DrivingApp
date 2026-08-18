import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/home/home_routes.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class RatePassengerPage extends StatefulWidget {
  final String rideId;
  final String passengerId;
  final String passengerName;

  const RatePassengerPage({
    super.key,
    required this.rideId,
    required this.passengerId,
    required this.passengerName,
  });

  @override
  State<RatePassengerPage> createState() => _RatePassengerPageState();
}

class _RatePassengerPageState extends State<RatePassengerPage> {
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
      if (mounted) _returnToDashboard();
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

  void _returnToDashboard() {
    if (!mounted) return;
    BlocProvider.of<RideFlowCubit>(context).reset();
    context.goNamed(HomeRoutes.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.borderSide, width: 2),
                    ),
                    child: const Icon(
                      LucideIcons.user,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Rate Your Passenger',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.passengerName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.tertiaryColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        onPressed: () => setState(() => _rating = index + 1),
                        icon: Icon(
                          LucideIcons.star,
                          color: index < _rating
                              ? AppTheme.accent
                              : AppTheme.borderSide,
                          size: 34,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _rating > 0 && !_isSubmitting ? _submit : null,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _rating > 0 && !_isSubmitting
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit Rating',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _isSubmitting ? null : _returnToDashboard,
                    child: const Text('Skip for now'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
