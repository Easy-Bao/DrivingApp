import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/activity/activity_routes.dart';
import 'package:shared_core/shared_core.dart';

class PassengerPaymentPage extends StatelessWidget {
  final RideHistoryModel ride;

  const PassengerPaymentPage({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final fare =
        double.tryParse(ride.price.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.complete.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppTheme.complete,
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Trip Completed',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pay ${ride.displayDriverName} in cash before you leave the vehicle.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.tertiaryColor,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 22,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppTheme.borderSide),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Cash Fare',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.tertiaryColor,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '₱${fare.toStringAsFixed(2)}',
                          key: const ValueKey('payment-total-fare'),
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.neutralColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.payments_outlined, size: 17),
                              SizedBox(width: 8),
                              Text(
                                'Cash Payment',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppTheme.tertiaryColor,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'After paying, continue to share feedback about your driver.',
                          style: TextStyle(
                            color: AppTheme.tertiaryColor,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    key: const ValueKey('confirm-cash-payment-button'),
                    onPressed: () => context.goNamed(
                      ActivityRoutes.passengerRating,
                      queryParameters: {
                        'driverId': ride.driverId,
                        'driverName': ride.driverName,
                        'rideId': ride.id,
                      },
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      'I Paid in Cash — Rate Driver',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
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
