import 'package:driver_app/src/features/home/home_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

class RatePassengerScreen extends StatefulWidget {
  const RatePassengerScreen({super.key});

  @override
  State<RatePassengerScreen> createState() => _RatePassengerScreenState();
}

class _RatePassengerScreenState extends State<RatePassengerScreen> {
  int _rating = 0;

  static const _labels = {
    0: 'Tap to rate',
    1: 'Bad experience',
    2: 'Great passenger!',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              _buildAvatar(),
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
              const Text(
                'Juan D. Cruz',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.tertiaryColor,
                ),
              ),
              const SizedBox(height: 44),
              _buildThumbs(),
              const SizedBox(height: 14),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _labels[_rating] ?? '',
                  key: ValueKey(_rating),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const Spacer(),
              _buildSubmitButton(context),
              const SizedBox(height: 12),
              _buildSkipButton(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
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
    );
  }

  Widget _buildThumbs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _thumb(LucideIcons.thumbs_down, 1, AppTheme.cancel),
        const SizedBox(width: 44),
        _thumb(LucideIcons.thumbs_up, 2, AppTheme.complete),
      ],
    );
  }

  Widget _thumb(IconData icon, int val, Color color) {
    final isSelected = _rating == val;
    return GestureDetector(
      onTap: () => setState(() => _rating = _rating == val ? 0 : val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.12)
              : AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderSide,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 34,
          color: isSelected
              ? color
              : AppTheme.primaryColor.withValues(alpha: 0.25),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        CustomToast.show(context, 'Rating submitted!');
        context.goNamed(HomeRoutes.dashboard);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 68,
        decoration: BoxDecoration(
          color: _rating > 0
              ? AppTheme.primaryColor
              : AppTheme.primaryColor.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(34),
          boxShadow: _rating > 0
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ]
              : null,
        ),
        child: const Center(
          child: Text(
            'Submit & Continue',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.goNamed(HomeRoutes.dashboard),
      child: Text(
        'Skip for now',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryColor.withValues(alpha: 0.38),
        ),
      ),
    );
  }
}
