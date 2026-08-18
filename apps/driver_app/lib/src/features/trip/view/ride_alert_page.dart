import 'dart:async';

import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/trip/view/widgets/ride_alert_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:driver_app/src/features/trip/data/datasources/bidding_remote_data_source.dart';
import 'package:shared_ui/shared_ui.dart';

class RideAlertPage extends StatefulWidget {
  final Map<String, dynamic>? rideData;
  const RideAlertPage({super.key, this.rideData});

  @override
  State<RideAlertPage> createState() => _RideAlertPageState();
}

class _RideAlertPageState extends State<RideAlertPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _timerCtrl;
  Timer? _autoDecline;

  late final String _rideId;
  late final String _pickup;
  late final String _dropoff;
  late final double _distance;
  late final double _fare;
  late final String _duration;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    final rideData = widget.rideData ?? const <String, dynamic>{};
    _rideId = _readText(rideData['id']);
    _pickup = _readText(
      rideData['pickup_name'],
      fallback: 'Pickup location unavailable',
    );
    _dropoff = _readText(
      rideData['dropoff_name'],
      fallback: 'Destination unavailable',
    );
    _distance = _readNumber(rideData['distance']);
    _fare = _readNumber(rideData['fare']);
    _duration = _readText(
      rideData['duration'],
      fallback: 'Duration unavailable',
    );

    _timerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    if (_rideId.isNotEmpty) {
      _timerCtrl.forward();
      _autoDecline = Timer(const Duration(seconds: 15), () {
        if (mounted) {
          CustomToast.show(context, 'Ride request expired', isError: true);
          context.pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _timerCtrl.dispose();
    _autoDecline?.cancel();
    super.dispose();
  }

  Future<void> _accept() async {
    if (_rideId.isEmpty || _isSubmitting) {
      CustomToast.show(
        context,
        'Ride request is no longer available.',
        isError: true,
      );
      return;
    }

    setState(() => _isSubmitting = true);
    _autoDecline?.cancel();

    var submitted = false;
    try {
      submitted = await Modular.get<BiddingRemoteDataSource>().placeBid(
        sessionId: _rideId,
        offerPrice: _fare,
        proposedFare: _fare,
      );

      if (!mounted) return;
      if (submitted) {
        CustomToast.show(context, 'Offer submitted! Waiting for passenger...');
        context.pop();
      } else {
        setState(() => _isSubmitting = false);
        CustomToast.show(context, 'Failed to submit offer.', isError: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        CustomToast.show(
          context,
          'Unable to submit the offer. Please try again.',
          isError: true,
        );
      }
    }
  }

  void _decline() {
    _autoDecline?.cancel();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.34),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth > 600.0;
            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isWide ? 600.0 : double.infinity,
                  maxHeight: constraints.maxHeight * 0.76,
                ),
                child: SingleChildScrollView(
                  child: RideAlertCardWidget(
                    pickup: _pickup,
                    dropoff: _dropoff,
                    distance: _distance,
                    fare: _fare,
                    duration: _duration,
                    timerController: _timerCtrl,
                    isSubmitting: _isSubmitting,
                    onAcceptPressed: _accept,
                    onDeclinePressed: _decline,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

String _readText(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

double _readNumber(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
