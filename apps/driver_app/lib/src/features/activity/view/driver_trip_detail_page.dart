import 'package:driver_app/src/core/formatters/driver_value_formatters.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/chat/chat_routes.dart';
import 'package:driver_app/src/features/chat/data/datasources/chat_room_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:shared_ui/shared_ui.dart';

class DriverTripDetailPage extends StatefulWidget {
  final Map<String, dynamic> trip;

  const DriverTripDetailPage({super.key, required this.trip});

  @override
  State<DriverTripDetailPage> createState() => _DriverTripDetailPageState();
}

class _DriverTripDetailPageState extends State<DriverTripDetailPage> {
  String get _passengerName =>
      driverValueAsString(widget.trip['passenger_name']) ?? 'Passenger';

  String get _passengerPhone =>
      driverValueAsString(widget.trip['passenger_phone']) ??
      'Phone unavailable';

  String? get _passengerFeedback =>
      driverValueAsString(widget.trip['passenger_feedback']);

  double? get _passengerRating {
    final value = widget.trip['passenger_rating'];
    if (value is num && value.isFinite && value > 0) return value.toDouble();
    return double.tryParse(driverValueAsString(value) ?? '');
  }

  Future<void> _contactPassenger() async {
    final passengerId = driverValueAsString(widget.trip['passenger_id']);
    final tripId = driverValueAsString(widget.trip['id']);
    if (passengerId == null || tripId == null) return;

    final driverId =
        await Modular.get<SecureSessionService>().readDriverId() ?? '';
    if (driverId.isEmpty) return;

    try {
      final initialized = await Modular.get<ChatRoomRemoteDataSource>()
          .initializeRoom(
            roomId: tripId,
            driverId: driverId,
            passengerId: passengerId,
          );

      if (!mounted) return;
      if (initialized) {
        context.pushNamed(
          ChatRoutes.chat,
          extra: {
            'roomId': tripId,
            'userId': driverId,
            'peerName': _passengerName,
          },
        );
      } else {
        CustomToast.show(
          context,
          'Failed to initialize chat channel.',
          isError: true,
        );
      }
    } catch (_) {
      if (!mounted) return;
      CustomToast.show(
        context,
        'Connection failed to start chat.',
        isError: true,
      );
    }
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Past trip';
    }
  }

  String _formatDistance() {
    final value = widget.trip['distance_km'];
    if (value is num && value.isFinite && value > 0) {
      return '${value.toStringAsFixed(1)} km';
    }
    return '—';
  }

  String _formatDuration() {
    final value = widget.trip['duration_minutes'];
    if (value is num && value.isFinite && value > 0) {
      return '${value.round()} min';
    }
    return '—';
  }

  @override
  Widget build(BuildContext context) {
    final status = (driverValueAsString(widget.trip['status']) ?? 'completed')
        .toLowerCase();
    final isCompleted = status == 'completed';
    final isCanceled = status == 'canceled' || status == 'cancelled';
    final statusColor = isCompleted ? AppTheme.complete : AppTheme.cancel;
    final statusLabel = isCompleted
        ? 'Completed'
        : isCanceled
        ? 'Canceled'
        : driverSentenceCase(status, 'Past trip');
    final fromName =
        driverValueAsString(widget.trip['pickup_name']) ?? 'Pickup';
    final toName =
        driverValueAsString(widget.trip['dropoff_name']) ?? 'Drop-off';
    final fare = driverFareInPesos(widget.trip);
    final rideType = driverSentenceCase(widget.trip['ride_type'], 'Solo ride');
    final dateValue =
        driverValueAsString(widget.trip['completed_at']) ??
        driverValueAsString(widget.trip['created_at']) ??
        '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(LucideIcons.arrow_left),
          onPressed: () => context.pop(),
        ),
        title: const Text('Trip details'),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360 ? 16.0 : 24.0;
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                12,
                horizontalPadding,
                32,
              ),
              physics: const BouncingScrollPhysics(),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Past trip',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.tertiaryColor,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _formatDate(dateValue),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.42,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusChip(statusLabel, statusColor),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildTripSummaryCard(
                        fromName: fromName,
                        toName: toName,
                        rideType: rideType,
                        fare: fare,
                        distance: _formatDistance(),
                        duration: _formatDuration(),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Passenger profile',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.tertiaryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildPassengerCard(),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _contactPassenger,
                        icon: const Icon(LucideIcons.message_square, size: 18),
                        label: const Text('Contact passenger'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTripSummaryCard({
    required String fromName,
    required String toName,
    required String rideType,
    required double? fare,
    required String distance,
    required String duration,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Trip route',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total fare',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor.withValues(alpha: 0.42),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fare == null ? '—' : '₱${fare.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            _buildRouteStop(
              icon: Icons.circle,
              label: 'Pickup',
              value: fromName,
              color: AppTheme.complete,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 5),
              child: Container(
                width: 2,
                height: 18,
                color: AppTheme.borderSide,
              ),
            ),
            _buildRouteStop(
              icon: Icons.location_on,
              label: 'Drop-off',
              value: toName,
              color: AppTheme.accent,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(child: _buildTripMetric('Ride type', rideType)),
                _buildMetricDivider(),
                Expanded(child: _buildTripMetric('Distance', distance)),
                _buildMetricDivider(),
                Expanded(child: _buildTripMetric('Duration', duration)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteStop({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 12,
          child: Icon(icon, size: icon == Icons.circle ? 9 : 15, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor.withValues(alpha: 0.42),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTripMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: double.infinity,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryColor.withValues(alpha: 0.42),
            ),
          ),
        ),
        const SizedBox(height: 3),
        SizedBox(
          width: double.infinity,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() {
    return Container(width: 1, height: 28, color: AppTheme.borderSide);
  }

  Widget _buildPassengerCard() {
    final rating = _passengerRating;
    final initial = _passengerName.substring(0, 1).toUpperCase();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _passengerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _passengerPhone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
                if (rating != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.complete.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${rating.toStringAsFixed(1)} rating',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.complete,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Text(
              _passengerFeedback ?? 'No feedback shared yet.',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: AppTheme.primaryColor.withValues(alpha: 0.62),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
