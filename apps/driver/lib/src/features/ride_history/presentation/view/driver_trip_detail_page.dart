import 'package:design_system/design_system.dart';
import 'package:driver/src/features/active_ride/domain/repositories/driver_ride_repository.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/driver_safety_report_sheet.dart';
import 'package:driver/src/features/chat/chat_routes.dart';
import 'package:driver/src/infrastructure/session/driver_session_store.dart';
import 'package:driver/src/presentation/formatters/driver_value_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';

class const TripDetailPage({
  super.key,
  required this.trip,
  required this.sessionService,
  this.rideRepository,
}) extends StatefulWidget {
  final Map<String, dynamic> trip;
  final SessionStore sessionService;
  final RideRepository? rideRepository;

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  static const _passengerContactWindow = Duration(hours: 24);

  bool _isContactingPassenger = false;
  String? _chatFeedbackMessage;

  String get _passengerName =>
      valueAsString(widget.trip['passenger_name']) ?? 'Passenger';

  String? get _passengerFeedback =>
      valueAsString(widget.trip['passenger_feedback']);

  double? get _passengerRating {
    final value = widget.trip['passenger_rating'];
    if (value is num && value.isFinite && value > 0) return value.toDouble();
    return double.tryParse(valueAsString(value) ?? '');
  }

  bool get _canContactPassenger {
    final status = (valueAsString(widget.trip['status']) ?? '').toLowerCase();
    if (status == 'assigned' ||
        status == 'accepted' ||
        status == 'arrived' ||
        status == 'in_transit') {
      return true;
    }
    if (status != 'completed') return false;

    final completedAtValue = valueAsString(widget.trip['completed_at']);
    if (completedAtValue == null) return false;
    final completedAt = DateTime.tryParse(completedAtValue);
    if (completedAt == null) return false;
    final age = DateTime.now().toUtc().difference(completedAt.toUtc());
    return !age.isNegative && age <= _passengerContactWindow;
  }

  Future<void> _contactPassenger() async {
    if (_isContactingPassenger || !_canContactPassenger) return;

    final passengerId = valueAsString(widget.trip['passenger_id']);
    final tripId = valueAsString(widget.trip['id']);
    if (passengerId == null || tripId == null) {
      _showChatFeedback('Chat Unavailable. Please Try Again.');
      return;
    }

    setState(() {
      _isContactingPassenger = true;
      _chatFeedbackMessage = null;
    });

    final driverId = await widget.sessionService.readDriverId() ?? '';
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
      if (!mounted) return;
      await context.pushNamed(
        ChatRoutes.chat,
        extra: {
          'roomId': tripId,
          'userId': driverId,
          'peerId': passengerId,
          'peerName': _passengerName,
        },
      );
    } catch (_) {
      if (!mounted) return;
      _showChatFeedback('Chat Unavailable Right Now. Please Try Again.');
    } finally {
      if (mounted) setState(() => _isContactingPassenger = false);
    }
  }

  void _showChatFeedback(String message) {
    if (!mounted || AppNetworkStatusScope.isUnavailableOf(context)) return;
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
    final status = (valueAsString(widget.trip['status']) ?? '').toLowerCase();
    final canContactPassenger = _canContactPassenger;
    final isCompleted = status == 'completed';
    final isCanceled = status == 'canceled' || status == 'cancelled';
    final statusColor = isCompleted
        ? context.semanticColors.success
        : context.colorScheme.error;
    final statusLabel = isCompleted
        ? 'Completed'
        : isCanceled
        ? 'Canceled'
        : sentenceCase(status, 'Past trip');
    final fromName = valueAsString(widget.trip['pickup_name']) ?? 'Pickup';
    final toName = valueAsString(widget.trip['dropoff_name']) ?? 'Drop-off';
    final fare = fareInPesos(widget.trip);

    final tripId = valueAsString(widget.trip['id']) ?? '';
    final dateValue =
        valueAsString(widget.trip['completed_at']) ??
        valueAsString(widget.trip['created_at']) ??
        '';

    final reference = valueAsString(widget.trip['booking_reference']) ?? '';
    return AppSecondaryPage(
      title: isCompleted ? 'Trip receipt' : 'Trip details',
      onBack: () => context.pop(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _formatDate(dateValue),
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppSurfaceCard(
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        context.colorScheme.surfaceContainerHighest,
                    foregroundColor: context.colorScheme.onSurface,
                    child: const Icon(LucideIcons.user_round),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _passengerName,
                      style: context.textStyles.titleMedium,
                    ),
                  ),
                  if (canContactPassenger)
                    IconButton(
                      key: const ValueKey('driver-trip-contact-passenger'),
                      tooltip: 'Message passenger',
                      onPressed: _isContactingPassenger
                          ? null
                          : _contactPassenger,
                      icon: const Icon(LucideIcons.message_circle),
                    ),
                ],
              ),
            ),
            if (_chatFeedbackMessage != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppErrorBanner(
                key: const ValueKey('driver-trip-chat-feedback'),
                message: _chatFeedbackMessage!,
                onRetry: _contactPassenger,
                onDismiss: () => setState(() => _chatFeedbackMessage = null),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppSurfaceCard(
              child: CompactRouteTimeline(pickup: fromName, dropoff: toName),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              statusLabel,
              style: context.textStyles.bodyMedium?.copyWith(
                color: statusColor,
              ),
            ),
            if (_passengerRating case final rating?) ...[
              const SizedBox(height: AppSpacing.lg),
              AppSurfaceCard(
                child: Row(
                  children: [
                    const Expanded(child: Text('Passenger rating')),
                    Text(rating.toStringAsFixed(1)),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(
                      Icons.star_rounded,
                      size: 20,
                      color: context.semanticColors.rating,
                    ),
                  ],
                ),
              ),
            ],
            if (_passengerFeedback case final feedback?) ...[
              const SizedBox(height: AppSpacing.md),
              Text(feedback, style: context.textStyles.bodyMedium),
            ],
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Fare details',
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppSurfaceCard(
              child: Row(
                children: [
                  const Expanded(child: Text('Total fare')),
                  Text(
                    fare == null ? 'Unavailable' : formatPesoAmount(fare),
                    style: context.textStyles.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (reference.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              TripReference(id: reference, compact: true),
            ],
            if (widget.rideRepository case final repository?
                when isCompleted && tripId.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              SafetyReportButton(
                bookingReference: reference,
                rideId: tripId,
                rideRepository: repository,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
