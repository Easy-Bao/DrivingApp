import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:design_system/design_system.dart';

class const DriverHelpCenterPage({super.key, this.onBack})
    extends StatelessWidget {
  final VoidCallback? onBack;

  static const topics = <AppHelpTopic>[
    AppHelpTopic(
      category: 'Going online',
      question: 'Why can’t I go online?',
      answer: 'Confirm that location services and BaoRide location permission are enabled. Your account and vehicle must also be active before ride requests can be received.',
    ),
    AppHelpTopic(
      category: 'Going online',
      question: 'Why did BaoRide switch me offline?',
      answer: 'BaoRide may switch you offline when location access is lost or your session expires. Restore access, sign in if needed, then try going online again.',
    ),
    AppHelpTopic(
      category: 'Trips',
      question: 'What should I do when I cannot find a passenger?',
      answer: 'Check the pickup pin and trip notes, move to a safe stopping point near the pin, and use the active trip contact action when it is available.',
    ),
    AppHelpTopic(
      category: 'Trips',
      question: 'When should I start a trip?',
      answer: 'Start the trip only after the passenger is inside the vehicle and the pickup details match the active request.',
    ),
    AppHelpTopic(
      category: 'Earnings',
      question: 'Where can I review completed trip earnings?',
      answer: 'Open Earnings from the bottom navigation to review totals. Completed trip details are also available from Trips.',
    ),
    AppHelpTopic(
      category: 'Account',
      question: 'How do I update my personal or vehicle details?',
      answer: 'Open Account, then choose Personal Details or Vehicle Information. Save appears after a field changes.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppHelpCenterPage(
      topics: topics,
      description: 'Find answers about going online, active trips, earnings, and your driver account.',
      onBack: onBack ?? () => context.pop(),
    );
  }
}
