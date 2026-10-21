import 'package:flutter/material.dart';
import 'package:passenger/src/core/session/session_store.dart';
import 'package:passenger/src/features/active_ride/domain/entities/ride_snapshot.dart';
import 'package:passenger/src/features/active_ride/domain/repositories/track_repository.dart';
import 'package:passenger/src/features/driver_profile/domain/repositories/driver_profile_repository.dart';
import 'package:passenger/src/features/ride_history/presentation/pages/ride_details_page.dart';

/// Keeps the legacy completion route while using the shared ride receipt.
class const PaymentPage({
  super.key,
  required this.ride,
  required this.trackRepository,
  required this.sessionService,
  required this.profileRepository,
}) extends StatelessWidget {
  final RideSnapshot ride;
  final TrackRepository trackRepository;
  final SessionStore sessionService;
  final DriverProfileRepository profileRepository;

  @override
  Widget build(BuildContext context) {
    return RideDetailsPage(
      initialRide: ride,
      rideId: ride.id,
      trackRepository: trackRepository,
      sessionService: sessionService,
      profileRepository: profileRepository,
    );
  }
}
