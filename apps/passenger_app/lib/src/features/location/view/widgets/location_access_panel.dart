import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';

class LocationAccessPrompt extends StatelessWidget {
  const LocationAccessPrompt({
    super.key,
    required this.onEnable,
    required this.onSkip,
  });

  final VoidCallback onEnable;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return _LocationPageScaffold(
      child: Column(
        children: [
          const Spacer(),
          const _LocationIllustration(
            icon: LucideIcons.map_pin,
            iconColor: AppTheme.complete,
          ),
          const SizedBox(height: 28),
          const Text(
            'Make every pickup easier',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 27,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'BaoRide uses your location to find nearby drivers and place your pickup accurately.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.tertiaryColor,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          const _LocationBenefit(
            icon: LucideIcons.car_front,
            title: 'See nearby rides faster',
            message: 'Get a clearer view of available drivers around you.',
          ),
          const SizedBox(height: 12),
          const _LocationBenefit(
            icon: LucideIcons.navigation,
            title: 'Set the right pickup point',
            message: 'Reduce missed pickups with a more accurate location.',
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onEnable,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.complete,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text('Turn on location'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.tertiaryColor,
              minimumSize: const Size.fromHeight(44),
            ),
            child: const Text('Not now'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class LocationUnavailableView extends StatelessWidget {
  const LocationUnavailableView({
    super.key,
    required this.onUpdateLocation,
    required this.onContinue,
  });

  final VoidCallback onUpdateLocation;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _LocationPageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 32),
          const Text(
            'We couldn’t locate you',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Choose a pickup area manually to keep exploring BaoRide without device location.',
            style: TextStyle(
              color: AppTheme.tertiaryColor,
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          const _ManualLocationIllustration(),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onUpdateLocation,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.complete,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: const Text('Update location'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onContinue,
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.tertiaryColor,
                minimumSize: const Size.fromHeight(44),
              ),
              child: const Text('Continue exploring'),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LocationPageScaffold extends StatelessWidget {
  const _LocationPageScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: child,
        ),
      ),
    );
  }
}

class _LocationIllustration extends StatelessWidget {
  const _LocationIllustration({required this.icon, required this.iconColor});

  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.42),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.complete.withValues(alpha: 0.15),
          width: 14,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Icon(icon, color: iconColor, size: 34),
          ),
        ),
      ),
    );
  }
}

class _LocationBenefit extends StatelessWidget {
  const _LocationBenefit({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppTheme.tertiaryColor,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualLocationIllustration extends StatelessWidget {
  const _ManualLocationIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(child: CustomPaint(painter: _MapLinesPainter())),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.complete,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.complete.withValues(alpha: 0.24),
                  blurRadius: 0,
                  spreadRadius: 12,
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Icon(LucideIcons.map_pin, color: Colors.white, size: 28),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.78)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final accentPaint = Paint()
      ..color = AppTheme.complete.withValues(alpha: 0.3)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final primaryRoad = Path()
      ..moveTo(-20, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.3,
        size.width + 20,
        size.height * 0.42,
      );
    final secondaryRoad = Path()
      ..moveTo(size.width * 0.12, -20)
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * 0.45,
        size.width * 0.82,
        size.height + 20,
      );
    canvas.drawPath(primaryRoad, roadPaint);
    canvas.drawPath(secondaryRoad, roadPaint);
    canvas.drawLine(
      Offset(size.width * 0.08, size.height * 0.15),
      Offset(size.width * 0.9, size.height * 0.82),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
