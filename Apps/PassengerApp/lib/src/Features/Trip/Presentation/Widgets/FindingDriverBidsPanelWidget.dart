import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverOfferItem {
  final String offerId;
  final String driverId;
  final String driverName;
  final String vehicleType;
  final String plateNumber;
  final String ratingStr;
  final double proposedFare;

  const DriverOfferItem({
    required this.offerId,
    required this.driverId,
    required this.driverName,
    required this.vehicleType,
    required this.plateNumber,
    required this.ratingStr,
    required this.proposedFare,
  });

  factory DriverOfferItem.fromMap(Map<String, dynamic> rawMap, double fallbackFare) {
    final offerId = rawMap['offer_id'] as String? ?? rawMap['id'] as String? ?? '';
    final driverName = rawMap['driver_name'] as String? ?? 'Driver';
    final vehicle = rawMap['vehicle_type'] as String? ?? 'Bao Bao';
    final plate = rawMap['plate_number'] as String? ?? '';
    final ratingStr = rawMap['driver_rating']?.toString() ?? '5.0';
    final proposedFare = (rawMap['proposed_fare'] as num?)?.toDouble() ?? fallbackFare;
    final driverId = rawMap['driver_id'] as String? ?? '';

    return DriverOfferItem(
      offerId: offerId,
      driverId: driverId,
      driverName: driverName,
      vehicleType: vehicle,
      plateNumber: plate,
      ratingStr: ratingStr,
      proposedFare: proposedFare,
    );
  }
}

class FindingDriverBidsPanelWidget extends StatelessWidget {
  final List<dynamic> offers;
  final double fallbackFare;
  final Function(DriverOfferItem offer) onAcceptOfferPressed;
  final VoidCallback onCancelPressed;

  const FindingDriverBidsPanelWidget({
    super.key,
    required this.offers,
    required this.fallbackFare,
    required this.onAcceptOfferPressed,
    required this.onCancelPressed,
  });

  @override
  Widget build(BuildContext context) {
    final parsedOffers = offers
        .whereType<Map<String, dynamic>>()
        .map((m) => DriverOfferItem.fromMap(m, fallbackFare))
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppTheme.borderSide,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Select Driver Offer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Drivers nearby have placed these bids for your trip',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: parsedOffers.length,
              itemBuilder: (context, index) {
                final offer = parsedOffers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.neutralColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderSide),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.user,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.driverName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${offer.vehicleType} • ${offer.plateNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.star,
                                  color: Colors.amber,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  offer.ratingStr,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₱${offer.proposedFare.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => onAcceptOfferPressed(offer),
                            child: const Text(
                              'Accept',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: onCancelPressed,
            child: Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppTheme.cancel.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Text(
                'Cancel Ride Request',
                style: TextStyle(
                  color: AppTheme.cancel,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
