import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/trip_booking/trip_routes.dart';
import 'package:passenger_services/passenger_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

class PassengerRatingScreen extends StatefulWidget {
  final String driverId;
  final String driverName;

  const PassengerRatingScreen({
    super.key,
    required this.driverId,
    required this.driverName,
  });

  @override
  State<PassengerRatingScreen> createState() => _PassengerRatingScreenState();
}

class _PassengerRatingScreenState extends State<PassengerRatingScreen> {
  int _selectedStars = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  void _finishRating() {
    unawaited(_submitRating());
  }

  Future<void> _submitRating() async {
    if (_selectedStars == 0) {
      CustomToast.show(context, 'Please select a rating.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final passengerName = prefs.getString('passenger_name') ?? 'Passenger';

      await Modular.get<PassengerApiService>().submitDriverReview(
        driverId: widget.driverId,
        passengerName: passengerName,
        rating: _selectedStars.toDouble(),
        comment: _feedbackController.text.trim(),
      );

      if (mounted) {
        CustomToast.show(context, 'Thank you for your feedback!');
        context.goNamed(TripRoutes.passengerHome);
      }
    } catch (error) {
      if (mounted) {
        CustomToast.show(context, 'Failed to submit review: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _checkForgottenItemsAndFinish() async {
    final bool? confirmFinishRatingSession = await showDialog<bool>(
      context: context,
      builder: (BuildContext checkBelongingsDialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: AppTheme.surface,
          title: const Row(
            children: [
              Icon(LucideIcons.triangle_alert, color: Colors.orange, size: 24),
              SizedBox(width: 12),
              Text(
                'Check Your Belongings',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            'Please take a moment to ensure you have not left any personal items behind in the vehicle.',
            style: TextStyle(color: AppTheme.primaryColor, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(checkBelongingsDialogContext).pop(false),
              child: Text(
                'Check Again',
                style: TextStyle(
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () =>
                  Navigator.of(checkBelongingsDialogContext).pop(true),
              child: const Text('All Good'),
            ),
          ],
        );
      },
    );

    if (confirmFinishRatingSession == true && mounted) {
      _finishRating();
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppTheme.secondaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.check,
                  color: AppTheme.primaryColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Ride Completed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'How was your trip with your driver?',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedStars = index + 1;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        index < _selectedStars
                            ? LucideIcons.star
                            : LucideIcons.star,
                        color: index < _selectedStars
                            ? Colors.amber
                            : AppTheme.borderSide,
                        size: 40,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 40),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neutralColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderSide),
                ),
                child: TextField(
                  controller: _feedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Leave a feedback (optional)',
                    hintStyle: TextStyle(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 15,
                  ),
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: _isSubmitting ? null : _finishRating,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: _isSubmitting ? AppTheme.primaryColor.withValues(alpha: 0.5) : AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  alignment: Alignment.center,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
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
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _checkForgottenItemsAndFinish,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  alignment: Alignment.center,
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
