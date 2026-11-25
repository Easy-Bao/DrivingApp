import 'package:design_system/design_system.dart';
import 'package:driver/src/core/formatters/value_formatters.dart';
import 'package:driver/src/core/session/session_store.dart';
import 'package:driver/src/features/active_ride/domain/repositories/ride_repository.dart';
import 'package:driver/src/features/active_ride/presentation/widgets/safety_report_sheet.dart';
import 'package:driver/src/features/chat/chat_routes.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:material_ui/material_ui.dart';

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
    final fromName = valueAsString(widget.trip['pickup_name']) ?? 'Pickup';
    final toName = valueAsString(widget.trip['dropoff_name']) ?? 'Drop-off';
    final fare = fareInPesos(widget.trip);

    final tripId = valueAsString(widget.trip['id']) ?? '';
    final dateValue =
        valueAsString(widget.trip['completed_at']) ??
        valueAsString(widget.trip['created_at']) ??
        '';
    final reference = valueAsString(widget.trip['booking_reference']) ?? '';

    return TripReceiptLayout(
      dateLabel: _formatDate(dateValue),
      onBack: () => context.pop(),
      child: Builder(
        builder: (context) {
          final colorScheme = context.colorScheme;
          final textStyles = context.textStyles;
          final statusColor = isCompleted
              ? context.semanticColors.success
              : isCanceled
              ? colorScheme.error
              : colorScheme.onSurfaceVariant;
          final statusLabel = isCompleted
              ? 'Completed'
              : isCanceled
              ? 'Canceled'
              : sentenceCase(status, 'Past trip');
          final hairline = Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (reference.isNotEmpty) ...[
                TripReference(id: reference, expanded: true, compact: true),
                const SizedBox(height: AppSpacing.md),
                hairline,
                const SizedBox(height: AppSpacing.xl),
              ],
              const _SectionHeader(label: 'Passenger'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.outlineVariant),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        LucideIcons.user_round,
                        size: 18,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _passengerName,
                      style: textStyles.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (canContactPassenger)
                    IconButton(
                      key: const ValueKey('driver-trip-contact-passenger'),
                      tooltip: 'Message passenger',
                      onPressed: _isContactingPassenger
                          ? null
                          : _contactPassenger,
                      style:
                          IconButton.styleFrom(
                            backgroundColor: colorScheme.surfaceContainerLowest,
                            foregroundColor: colorScheme.onSurface,
                            side: BorderSide(color: colorScheme.outlineVariant),
                            shape: const CircleBorder(),
                            enableFeedback: false,
                            splashFactory: NoSplash.splashFactory,
                          ).copyWith(
                            overlayColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.focused)) {
                                return colorScheme.primary.withValues(
                                  alpha: 0.12,
                                );
                              }
                              return Colors.transparent;
                            }),
                          ),
                      icon: const Icon(LucideIcons.message_circle, size: 18),
                    ),
                ],
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
              const SizedBox(height: AppSpacing.xl),
              hairline,
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  const Expanded(child: _SectionHeader(label: 'Route')),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExcludeSemantics(
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: textStyles.labelSmall?.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              CompactRouteTimeline(pickup: fromName, dropoff: toName),
              if (_passengerRating != null || _passengerFeedback != null) ...[
                const SizedBox(height: AppSpacing.xl),
                hairline,
                const SizedBox(height: AppSpacing.xl),
                if (_passengerRating case final rating?)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Passenger rating',
                          style: textStyles.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Text(
                        rating.toStringAsFixed(1),
                        style: textStyles.titleSmall?.tabular.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      ExcludeSemantics(
                        child: Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: context.semanticColors.rating,
                        ),
                      ),
                    ],
                  ),
                if (_passengerFeedback case final feedback?) ...[
                  if (_passengerRating != null)
                    const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.only(left: AppSpacing.md),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      feedback,
                      style: textStyles.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: AppSpacing.xl),
              hairline,
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Fare details',
                style: textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      'Total fare',
                      style: textStyles.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    fare == null ? 'Unavailable' : formatPesoAmount(fare),
                    style: textStyles.headlineSmall?.tabular.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              hairline,
              if (widget.rideRepository case final repository?
                  when isCompleted && tripId.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: SafetyReportButton(
                    rideId: tripId,
                    rideRepository: repository,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class const _SectionHeader({required this.label}) extends StatelessWidget {
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        label.toUpperCase(),
        style: context.textStyles.labelSmall?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.9,
        ),
      ),
    );
  }
}
