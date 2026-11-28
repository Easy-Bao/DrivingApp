import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class TripEndedDialog extends StatelessWidget {
  const TripEndedDialog({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppConfirmDialog(
      title: title,
      message: message,
      confirmLabel: 'Back to dispatch',
      icon: LucideIcons.triangle_alert,
      tone: AppConfirmDialogTone.warning,
      canPop: false,
      onConfirm: () => Navigator.of(context).pop(),
    );
  }
}
