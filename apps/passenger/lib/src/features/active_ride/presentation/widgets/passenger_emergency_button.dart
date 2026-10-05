import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _emergencyContactNumber = '911';

typedef PassengerEmergencyStopCallback = Future<bool> Function(
  String reason,
  String details,
);

const _passengerEmergencyStopReasons = <String, String>{
  'accident': 'Accident or collision',
  'medical_emergency': 'Medical emergency',
  'threat_or_violence': 'Threat or violence',
  'vehicle_breakdown': 'Vehicle breakdown',
  'road_hazard': 'Road hazard or disaster',
  'police_or_disaster': 'Police checkpoint or disaster',
  'other': 'Other serious emergency',
};

Future<bool> showPassengerEmergencyActionSheet(
  BuildContext context, {
  required PassengerEmergencyStopCallback onEmergencyStop,
}) async {
  return await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            _PassengerEmergencyStopSheet(onEmergencyStop: onEmergencyStop),
      ) ??
      false;
}

class const _PassengerEmergencyStopSheet({required this.onEmergencyStop})
    extends StatefulWidget {
  final PassengerEmergencyStopCallback onEmergencyStop;

  @override
  State<_PassengerEmergencyStopSheet> createState() =>
      _PassengerEmergencyStopSheetState();
}

class _PassengerEmergencyStopSheetState
    extends State<_PassengerEmergencyStopSheet> {
  String? _selectedReason;
  String _details = '';
  String? _errorMessage;
  bool _isSubmitting = false;

  Future<void> _submit() async {
    final reason = _selectedReason;
    final details = _details.trim();
    if (reason == null) {
      setState(() => _errorMessage = 'Choose the emergency reason first.');
      return;
    }
    if (reason == 'other' && details.isEmpty) {
      setState(() => _errorMessage = 'Add details when choosing Other.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('End ride for safety?'),
        content: const Text(
          'This will close the active ride and record a safety event. It will not settle or waive any cash fare automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep ride'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('End ride'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final stopped = await widget.onEmergencyStop(reason, details);
      if (!mounted) return;
      if (stopped) {
        Navigator.pop(context, true);
        return;
      }
      setState(() {
        _isSubmitting = false;
        _errorMessage =
            'The ride could not be ended for safety. Please try again.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'The emergency stop could not be submitted.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Material(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(EasyRideRadius.sheet),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            EasyRideSpacing.lg,
            EasyRideSpacing.lg,
            EasyRideSpacing.lg,
            EasyRideSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Emergency SOS',
                style: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Call 911 immediately if anyone is in danger. You can also end this ride so the safety event is recorded.',
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: EasyRideSize.minimumTouchTarget,
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () =>
                            unawaited(showPassengerEmergencyContacts(context)),
                  icon: const Icon(Icons.phone_in_talk_outlined),
                  label: const Text('Call emergency services (911)'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colorScheme.error,
                    side: BorderSide(color: context.colorScheme.error),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              EasyRideSelectField<String>(
                key: const ValueKey('passenger-emergency-reason-dropdown'),
                value: _selectedReason,
                menuTitle: 'Why are you ending the ride?',
                decoration: const InputDecoration(
                  labelText: 'Why are you ending the ride?',
                ),
                options: [
                  for (final entry in _passengerEmergencyStopReasons.entries)
                    EasyRideSelectOption<String>(
                      value: entry.key,
                      label: entry.value,
                    ),
                ],
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() {
                          _selectedReason = value;
                          _errorMessage = null;
                        });
                      },
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('passenger-emergency-details'),
                maxLength: 500,
                maxLines: 3,
                enabled: !_isSubmitting,
                onChanged: (value) {
                  _details = value;
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'What happened? (optional unless Other)',
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: context.colorScheme.error),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                height: EasyRideSize.minimumTouchTarget,
                child: FilledButton.icon(
                  onPressed: _selectedReason == null || _isSubmitting
                      ? null
                      : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.stop_circle_outlined),
                  label: Text(
                    _isSubmitting ? 'Ending ride…' : 'End ride for safety',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showPassengerEmergencyContacts(BuildContext context) async {
  final emergencyUri = Uri(scheme: 'tel', path: _emergencyContactNumber);
  var launched = false;
  try {
    launched =
        await canLaunchUrl(emergencyUri) && await launchUrl(emergencyUri);
  } catch (_) {
    launched = false;
  }
  if (launched || !context.mounted) return;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Emergency contacts'),
      content: const Text(
        'Your device cannot open the phone dialer. Call emergency services at 911.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
