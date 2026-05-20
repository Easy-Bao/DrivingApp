import 'package:flutter/material.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class RatePassengerScreen extends StatefulWidget {
  const RatePassengerScreen({super.key});
  @override
  State<RatePassengerScreen> createState() => _RatePassengerScreenState();
}

class _RatePassengerScreenState extends State<RatePassengerScreen> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Passenger avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  LucideIcons.user,
                  color: AppTheme.primaryColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Rate Your Passenger",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Juan D. Cruz",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.tertiaryColor,
                ),
              ),
              const SizedBox(height: 40),
              // Thumbs
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _thumb(LucideIcons.thumbs_down, 1, AppTheme.cancel),
                  const SizedBox(width: 40),
                  _thumb(LucideIcons.thumbs_up, 2, AppTheme.complete),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _rating == 0
                    ? "Tap to rate"
                    : _rating == 1
                    ? "Bad experience"
                    : "Great passenger!",
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Submit
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Rating submitted!"),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppTheme.complete,
                    ),
                  );
                  context.goNamed("DriverDashboard");
                },
                child: Container(
                  width: double.infinity,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _rating > 0
                        ? AppTheme.primaryColor
                        : AppTheme.primaryColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: const Center(
                    child: Text(
                      "Submit & Continue",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => context.goNamed("DriverDashboard"),
                child: Text(
                  "Skip",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb(IconData icon, int val, Color color) {
    final isSel = _rating == val;
    return GestureDetector(
      onTap: () => setState(() => _rating = _rating == val ? 0 : val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.15) : AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSel ? color : AppTheme.borderSide,
            width: isSel ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 32,
          color: isSel ? color : AppTheme.primaryColor.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
