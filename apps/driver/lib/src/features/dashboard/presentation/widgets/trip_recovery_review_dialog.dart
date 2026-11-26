import 'package:material_ui/material_ui.dart';

class const TripRecoveryReviewDialog({super.key, required this.isInTransit})
    extends StatelessWidget {
  final bool isInTransit;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Review this trip'),
      content: Text(
        isInTransit
            ? 'This trip has been open longer than expected. Confirm the trip status with your passenger before continuing.'
            : 'This pickup has been waiting longer than expected. Check with the passenger, then continue or use the cancellation action on the trip screen.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Open trip'),
        ),
      ],
    );
  }
}
