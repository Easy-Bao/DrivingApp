import 'package:driver_app/src/features/profile/presentation/widgets/driver_account_details_form.dart';
import 'package:flutter/material.dart';

class DriverVehicleInformationPage extends StatelessWidget {
  const DriverVehicleInformationPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return DriverAccountDetailsForm(
      section: DriverAccountDetailsSection.vehicle,
      onBack: onBack,
    );
  }
}
