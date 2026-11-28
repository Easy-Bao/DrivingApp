import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:material_ui/material_ui.dart';

class const TripRecoveryReviewDialog({super.key, required this.isInTransit})
    extends StatelessWidget {
  final bool isInTransit;

  @override
  Widget build(BuildContext context) {
    return AppConfirmDialog(
      title: 'Review this trip',
      message: isInTransit
          ? 'This trip has been open longer than expected. Confirm the trip status with your passenger before continuing.'
          : 'This pickup has been waiting longer than expected. Check with the passenger, then continue or use the cancellation action on the trip screen.',
      confirmLabel: 'Open trip',
      cancelLabel: 'Not now',
      icon: LucideIcons.circle_alert,
      tone: AppConfirmDialogTone.warning,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    );
  }
}
