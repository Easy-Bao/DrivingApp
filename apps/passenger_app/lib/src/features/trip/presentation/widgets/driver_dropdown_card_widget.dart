import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverDropdownCardWidget extends StatefulWidget {
  final DriverModel driver;
  final bool isNearestDriver;
  final VoidCallback onViewFullProfilePressed;
  final VoidCallback onSelectDriverPressed;
  final VoidCallback onCloseDropdownPressed;

  const DriverDropdownCardWidget({
    super.key,
    required this.driver,
    required this.isNearestDriver,
    required this.onViewFullProfilePressed,
    required this.onSelectDriverPressed,
    required this.onCloseDropdownPressed,
  });

  @override
  State<DriverDropdownCardWidget> createState() =>
      _DriverDropdownCardWidgetState();
}

class _DriverDropdownCardWidgetState extends State<DriverDropdownCardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dropdownAnimationController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _dropdownAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _dropdownAnimationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _dropdownAnimationController,
      curve: Curves.easeIn,
    );

    unawaited(_dropdownAnimationController.forward());
  }

  @override
  void dispose() {
    _dropdownAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableWidth = MediaQuery.sizeOf(context).width;
    final isCompactScreen = availableWidth <= 600.0;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520.0),
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: isCompactScreen ? 16.0 : 24.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.12),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 24.0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 56.0,
                          height: 56.0,
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.isNearestDriver
                                  ? AppTheme.primaryColor
                                  : Colors.transparent,
                              width: 2.0,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.user,
                            color: AppTheme.primaryColor,
                            size: 28.0,
                          ),
                        ),
                        const SizedBox(width: 14.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      widget.driver.name,
                                      style: const TextStyle(
                                        fontSize: 18.0,
                                        fontWeight: FontWeight.w900,
                                        color: AppTheme.primaryColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (widget.isNearestDriver) ...[
                                    const SizedBox(width: 6.0),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 3.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12.0),
                                      ),
                                      child: const Text(
                                        'Top Match',
                                        style: TextStyle(
                                          fontSize: 10.0,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                '${widget.driver.vehicleType} • ${widget.driver.plateNumber}',
                                style: TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onCloseDropdownPressed,
                          icon: const Icon(
                            LucideIcons.x,
                            size: 20.0,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 5.0,
                          ),
                          decoration: BoxDecoration(
                            color: widget.driver.hasPassengerOnboard
                                ? Colors.amber.withValues(alpha: 0.15)
                                : Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20.0),
                            border: Border.all(
                              color: widget.driver.hasPassengerOnboard
                                  ? Colors.amber.shade700
                                  : Colors.green.shade700,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.driver.hasPassengerOnboard
                                    ? LucideIcons.users
                                    : LucideIcons.user_check,
                                size: 14.0,
                                color: widget.driver.hasPassengerOnboard
                                    ? Colors.amber.shade900
                                    : Colors.green.shade900,
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                widget.driver.hasPassengerOnboard
                                    ? 'Current passenger onboard'
                                    : 'Available (No passenger)',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                  color: widget.driver.hasPassengerOnboard
                                      ? Colors.amber.shade900
                                      : Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 16.0,
                            ),
                            const SizedBox(width: 4.0),
                            Text(
                              widget.driver.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              '${widget.driver.distanceKm.toStringAsFixed(1)} km away',
                              style: TextStyle(
                                fontSize: 12.0,
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: AppTheme.neutralColor,
                        borderRadius: BorderRadius.circular(16.0),
                        border: Border.all(color: AppTheme.borderSide),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.message_square_quote,
                                size: 14.0,
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                'Recent Feedback',
                                style: TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            widget.driver.recentFeedback ??
                                'Professional service and well-maintained vehicle.',
                            style: TextStyle(
                              fontSize: 12.0,
                              height: 1.35,
                              color: AppTheme.primaryColor.withValues(alpha: 0.8),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: widget.onViewFullProfilePressed,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: const BorderSide(
                                color: AppTheme.primaryColor,
                                width: 1.5,
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                            child: const Text(
                              'View Full Profile',
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onSelectDriverPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                            child: const Text(
                              'Select Driver',
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
