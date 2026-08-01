import 'dart:async';

import 'package:driver_app/src/Features/Trip/Presentation/Widgets/RideAlertCardWidget.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/Core/Services/SecureSessionService.dart';
import 'package:driver_app/src/Features/Trip/Data/DataSources/BiddingRemoteDataSource.dart';
import 'package:shared_ui/SharedUi.dart';


class RideAlertScreen extends StatefulWidget {
  final Map<String, dynamic>? rideData;
  const RideAlertScreen({super.key, this.rideData});

  @override
  State<RideAlertScreen> createState() => _RideAlertScreenState();
}

class _RideAlertScreenState extends State<RideAlertScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerCtrl;
  Timer? _autoDecline;

  late final String _rideId;
  late final String _pickup;
  late final String _dropoff;
  late final double _distance;
  late final double _fare;
  late final String _duration;

  @override
  void initState() {
    super.initState();

    _rideId = widget.rideData?['id'] as String? ?? 'mock_id';
    _pickup =
        widget.rideData?['pickup_name'] as String? ??
        'SM City Dipolog, Rizal Ave';
    _dropoff =
        widget.rideData?['dropoff_name'] as String? ??
        'Dipolog Public Market, Quezon St';
    _distance = (widget.rideData?['distance'] ?? 3.2) as double;
    _fare = (widget.rideData?['fare'] ?? 52.00) as double;
    _duration = widget.rideData?['duration'] as String? ?? '8 min';

    _timerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..forward();
    _autoDecline = Timer(const Duration(seconds: 15), () {
      if (mounted) {
        CustomToast.show(context, 'Ride request expired', isError: true);
        context.pop();
      }
    });
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    _autoDecline?.cancel();
    super.dispose();
  }

  Future<void> _accept() async {
    _autoDecline?.cancel();

    final driverId = await Modular.get<SecureSessionService>().readDriverId() ?? 'driver_demo';

    final success = await Modular.get<BiddingRemoteDataSource>().placeBid(
      sessionId: _rideId,
      driverId: driverId,
      offerPrice: _fare,
      proposedFare: _fare,
    );


    if (mounted) {
      if (success) {
        CustomToast.show(context, 'Offer submitted! Waiting for passenger...');
      } else {
        CustomToast.show(context, 'Failed to submit offer.', isError: true);
      }
      context.pop();
    }
  }

  void _decline() {
    _autoDecline?.cancel();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.4),
      body: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: LayoutBuilder(
            builder: (ctx, constraints) {
              final isWide = constraints.maxWidth > 600.0;
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 600.0 : double.infinity,
                ),
                child: RideAlertCardWidget(
                  pickup: _pickup,
                  dropoff: _dropoff,
                  distance: _distance,
                  fare: _fare,
                  duration: _duration,
                  timerController: _timerCtrl,
                  onAcceptPressed: _accept,
                  onDeclinePressed: _decline,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
