import 'package:driver/src/features/profile/presentation/widgets/driver_account_details_form.dart';
import 'package:flutter/material.dart';

class const DriverPersonalDetailsPage({super.key, this.onBack})
    extends StatelessWidget {
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return DriverAccountDetailsForm(
      section: DriverAccountDetailsSection.personal,
      onBack: onBack,
    );
  }
}
