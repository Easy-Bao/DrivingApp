import 'dart:async';
import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:location_service/location_service.dart';
import 'package:passenger_app/core/themes/app_themes.dart';

/**
 * Trip details screen for a completed ride.
 *
 * Receives a [RideHistoryModel] via GoRouter's `extra` argument.
 * Renders a live Mapbox map with the route between pickup and drop-off,
 * fare breakdown, timeline, and a re-book button.
 *
 * If `extra` is null (e.g. navigated without a model), the screen shows
 * a graceful fallback rather than crashing.
 */
class ActivityViewDetails extends StatefulWidget {
  final RideHistoryModel? ride;

  const ActivityViewDetails({super.key, this.ride});

  @override
  State<ActivityViewDetails> createState() => _ActivityViewDetailsState();
}

class _ActivityViewDetailsState extends State<ActivityViewDetails> {
  Future<void> _onMapCreated(AppMapController controller) async {
    final ride = widget.ride;
    if (ride == null) return;

    try {
      await MapProvider.addMarker(
        controller,
        ride.pickupLat,
        ride.pickupLng,
        isOrigin: true,
      );
      await MapProvider.addMarker(
        controller,
        ride.destLat,
        ride.destLng,
        isOrigin: false,
      );

      final route = await MapProvider.getRoute(
        ride.pickupLat,
        ride.pickupLng,
        ride.destLat,
        ride.destLng,
      );
      if (route != null) {
        await MapProvider.addPolyline(
          controller,
          route.polylinePoints,
          color: AppTheme.primaryColor,
          width: 4.0,
        );
      }

      await MapProvider.fitBounds(
        controller,
        [
          LatLng(ride.pickupLat, ride.pickupLng),
          LatLng(ride.destLat, ride.destLng),
        ],
        padding: 40.0,
      );
    } catch (error) {
      debugPrint('ActivityViewDetails._onMapCreated failed: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;

    // Derive map center from ride coords, or fall back to Pagadian City center.
    final centerLat = ride != null
        ? (ride.pickupLat + ride.destLat) / 2
        : 7.8300;
    final centerLng = ride != null
        ? (ride.pickupLng + ride.destLng) / 2
        : 123.4400;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrow_left, color: AppTheme.primaryColor),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Trip Details',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // — Map preview —
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.neutralColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.outlineBorderColor),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(23),
                child: MapProvider.buildMapView(
                  latitude: centerLat,
                  longitude: centerLng,
                  zoom: 13.0,
                  interactive: false,
                  onMapCreated: _onMapCreated,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // — Driver info row —
            Row(
              children: [
                const CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.secondaryColor,
                  child: Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride?.driverName.isNotEmpty == true
                            ? ride!.driverName
                            : 'Driver',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        ride?.vehiclePlate.isNotEmpty == true
                            ? ride!.vehiclePlate
                            : '—',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.tertiaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.star, color: AppTheme.primaryColor, size: 16),
                const Text(
                  ' —',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: AppTheme.outlineBorderColor),
            ),
            // — Fare summary —
            _buildFareSummaryCard(ride),
            const SizedBox(height: 24),
            // — Timeline —
            _buildTimeline(ride),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to search with the same destination pre-filled.
                unawaited(context.pushNamed(
                  'SearchDestination',
                  queryParameters: ride != null
                      ? {'destination': ride.destination}
                      : {},
                ));
              },
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Book this route again',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFareSummaryCard(RideHistoryModel? ride) {
    // Parse the stored price string back to a double for breakdown calculation.
    double total = 0;
    if (ride != null) {
      final cleaned = ride.price.replaceAll(RegExp(r'[₱,]'), '').trim();
      total = double.tryParse(cleaned) ?? 0;
    }
    final base = (total * 0.17).clamp(0.0, double.infinity);
    final distance = (total * 0.76).clamp(0.0, double.infinity);
    final fees = (total - base - distance).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineBorderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Fare Summary',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                ride?.price ?? '—',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _fareRow('Base Fare', '₱${base.toStringAsFixed(2)}'),
          _fareRow('Distance', '₱${distance.toStringAsFixed(2)}'),
          _fareRow('Fees', '₱${fees.toStringAsFixed(2)}'),
        ],
      ),
    );
  }

  Widget _buildTimeline(RideHistoryModel? ride) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Timeline',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 16),
        _timelineItem(
          ride?.pickup ?? 'Pickup',
          ride?.date ?? '',
          true,
        ),
        _timelineItem(
          ride?.destination ?? 'Destination',
          '',
          false,
        ),
      ],
    );
  }

  Widget _fareRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppTheme.unselectedItemColor, fontSize: 13),
        ),
        Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _timelineItem(String loc, String time, bool isTop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isTop ? Icons.circle : Icons.location_on,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            if (isTop)
              Container(width: 2, height: 30, color: AppTheme.outlineBorderColor),
          ],
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc, style: const TextStyle(fontWeight: FontWeight.w700)),
            if (time.isNotEmpty)
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.unselectedItemColor,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
