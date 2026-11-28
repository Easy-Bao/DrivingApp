import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const CancelBookingDialog({
  super.key,
  this.isActiveRequest = false,
  this.destinationName,
}) extends StatelessWidget {
  final bool isActiveRequest;
  final String? destinationName;

  @override
  Widget build(BuildContext context) {
    final destination = destinationName?.trim() ?? '';
    final title = isActiveRequest
        ? 'Cancel ride request?'
        : 'Cancel driver search?';
    final message = isActiveRequest
        ? destination.isNotEmpty
              ? 'Your ride request to $destination will be canceled and you will need to start a new search.'
              : 'Your ride request will be canceled and you will need to start a new search.'
        : destination.isNotEmpty
        ? 'Stop looking for drivers to $destination? You can start a new booking anytime.'
        : 'Stop looking for nearby drivers? You can start a new booking anytime.';
    final keepLabel = isActiveRequest ? 'Keep waiting' : 'Keep searching';
    final confirmLabel = isActiveRequest ? 'Cancel request' : 'Cancel search';

    return AppConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: keepLabel,
      confirmButtonKey: const ValueKey<String>('confirm-cancel-booking-button'),
      cancelButtonKey: const ValueKey<String>('keep-booking-button'),
      icon: isActiveRequest ? LucideIcons.circle_alert : LucideIcons.search_x,
      tone: AppConfirmDialogTone.destructive,
      isDestructive: true,
      onConfirm: () => Navigator.pop(context, true),
      onCancel: () => Navigator.pop(context, false),
    );
  }
}

Future<bool> showCancelBookingDialog(
  BuildContext context, {
  bool isActiveRequest = false,
  String? destinationName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => CancelBookingDialog(
      isActiveRequest: isActiveRequest,
      destinationName: destinationName,
    ),
  );
  return confirmed ?? false;
}
