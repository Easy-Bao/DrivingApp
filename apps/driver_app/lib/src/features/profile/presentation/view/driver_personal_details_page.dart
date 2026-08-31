import 'package:driver_app/src/features/profile/presentation/widgets/driver_account_details_form.dart';
import 'package:flutter/material.dart';

class DriverPersonalDetailsPage extends StatelessWidget {
  const DriverPersonalDetailsPage({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return DriverAccountDetailsForm(
      section: DriverAccountDetailsSection.personal,
      onBack: onBack,
    );
  }
}
