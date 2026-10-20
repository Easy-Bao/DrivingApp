import 'package:driver/src/features/profile/presentation/widgets/driver_account_details_form.dart';
import 'package:flutter/material.dart';

class const VehicleInformationPage({super.key, this.onBack})
    extends StatelessWidget {
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AccountDetailsForm(
      section: AccountDetailsSection.vehicle,
      onBack: onBack,
    );
  }
}
