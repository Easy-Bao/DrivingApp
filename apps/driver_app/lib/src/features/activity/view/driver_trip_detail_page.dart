import 'package:driver_app/src/core/formatters/driver_value_formatters.dart';
import 'package:driver_app/src/core/services/secure_session_service.dart';
import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:driver_app/src/features/chat/chat_routes.dart';
import 'package:driver_app/src/features/chat/data/datasources/chat_room_remote_data_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DriverTripDetailPage extends StatefulWidget {
  final Map<String, dynamic> trip;

  const DriverTripDetailPage({super.key, required this.trip});

  @override
  State<DriverTripDetailPage> createState() => _DriverTripDetailPageState();
}

class _DriverTripDetailPageState extends State<DriverTripDetailPage> {
  bool _isContactingPassenger = false;
  bool _chatResolved = false;
  String? _chatFeedbackMessage;

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
    if (_isContactingPassenger || _chatResolved) return;

    final passengerId = driverValueAsString(widget.trip['passenger_id']);
    final tripId = driverValueAsString(widget.trip['id']);
    if (passengerId == null || tripId == null) {
      _showChatFeedback('Chat Unavailable. Please Try Again.');
      return;
    }

    setState(() {
      _isContactingPassenger = true;
      _chatFeedbackMessage = null;
      _chatResolved = false;
    });

    final driverId =
        await Modular.get<SecureSessionService>().readDriverId() ?? '';
    if (driverId.isEmpty) {
      if (mounted) {
        setState(() {
          _isContactingPassenger = false;
          _chatFeedbackMessage = 'Chat Unavailable. Please Sign In Again.';
        });
      }
      return;
    }

    try {
      final initializationStatus = await Modular.get<ChatRoomRemoteDataSource>()
          .initializeRoom(
            roomId: tripId,
            driverId: driverId,
            passengerId: passengerId,
          );

      if (!mounted) return;
      switch (initializationStatus) {
        case ChatRoomInitializationStatus.opened:
          await context.pushNamed(
            ChatRoutes.chat,
            extra: {
              'roomId': tripId,
              'userId': driverId,
              'peerId': passengerId,
              'peerName': _passengerName,
            },
          );
        case ChatRoomInitializationStatus.resolved:
          setState(() {
            _chatResolved = true;
            _chatFeedbackMessage = 'This Chat Has Already Been Resolved.';
          });
        case ChatRoomInitializationStatus.unavailable:
          _showChatFeedback('Chat Unavailable Right Now. Please Try Again.');
      }
    } catch (_) {
      if (!mounted) return;
      _showChatFeedback('Chat Unavailable Right Now. Please Try Again.');
    } finally {
      if (mounted) setState(() => _isContactingPassenger = false);
    }
  }

  void _showChatFeedback(String message) {
    if (!mounted) return;
    setState(() => _chatFeedbackMessage = message);
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
          style: IconButton.styleFrom(shape: const CircleBorder()),
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
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
                      if (_chatFeedbackMessage != null) ...[
                        const SizedBox(height: 12),
                        _buildChatFeedback(),
                      ],
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _isContactingPassenger || _chatResolved
                            ? null
                            : _contactPassenger,
                        icon: _isContactingPassenger
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.surface,
                                ),
                              )
                            : const Icon(LucideIcons.message_square, size: 18),
                        label: Text(
                          _chatResolved
                              ? 'Chat Resolved'
                              : _isContactingPassenger
                              ? 'Opening Chat...'
                              : 'Contact Passenger',
                        ),
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

  Widget _buildChatFeedback() {
    final isResolved = _chatResolved;
    final color = isResolved ? AppTheme.complete : AppTheme.cancel;
    return Container(
      key: const ValueKey('driver-trip-chat-feedback'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isResolved ? LucideIcons.circle_check : LucideIcons.info,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _chatFeedbackMessage!,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
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
            _buildRouteTimeline(fromName: fromName, toName: toName),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1),
            ),
            Row(
              children: [
                Expanded(child: _buildTripMetric('Ride type', rideType)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteTimeline({
    required String fromName,
    required String toName,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Column(
            children: [
              const Icon(Icons.circle, size: 9, color: AppTheme.complete),
              SizedBox(
                width: 2,
                height: 24,
                child: CustomPaint(
                  key: const ValueKey('driver-trip-route-dashes'),
                  painter: _DashedRoutePainter(),
                ),
              ),
              const Icon(Icons.location_on, size: 15, color: AppTheme.accent),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRouteLocation('Pickup', fromName),
              const SizedBox(height: 14),
              _buildRouteLocation('Drop-off', toName),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRouteLocation(String label, String value) {
    return Column(
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

class _DashedRoutePainter extends CustomPainter {
  static const _dashHeight = 4.0;
  static const _gapHeight = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.tertiaryColor.withValues(alpha: 0.68);

    var top = 0.0;
    while (top < size.height) {
      final bottom = (top + _dashHeight).clamp(0.0, size.height).toDouble();
      if (bottom > top) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(0, top, size.width, bottom - top),
            Radius.circular(size.width / 2),
          ),
          paint,
        );
      }
      top += _dashHeight + _gapHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRoutePainter oldDelegate) => false;
}
