import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:design_system/design_system.dart';

class const HelpCenterPage({super.key, this.onBack}) extends StatelessWidget {
  final VoidCallback? onBack;

  static const topics = <AppHelpTopic>[
    AppHelpTopic(
      category: 'Rides',
      question: 'How do I book a ride?',
      answer: "Tap 'Enter destination' on Home, search for your destination or pin it on the map, then choose a ride and confirm the booking.",
    ),
    AppHelpTopic(
      category: 'Rides',
      question: 'How do I cancel a ride?',
      answer: "Open Activity, select the upcoming ride, and use 'Cancel Trip' before the ride begins.",
    ),
    AppHelpTopic(
      category: 'Rides',
      question: 'What is Share-Bao?',
      answer: 'Share-Bao lets you share a ride with other passengers heading in a similar direction when that option is available for your trip.',
    ),
    AppHelpTopic(
      category: 'Payments',
      question: 'How do I view a receipt?',
      answer: 'After a ride is completed, open Activity and choose View Details to see the fare breakdown and trip receipt.',
    ),
    AppHelpTopic(
      category: 'Account',
      question: 'How do I update my personal details?',
      answer: 'Open Account, select your profile header, update the available fields, and save your changes.',
    ),
    AppHelpTopic(
      category: 'Location',
      question: 'How do I restore location access?',
      answer: 'Open Account → Settings → Location access. Turn on the phone location service or grant the app permission, then return to BaoRide and try again.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppHelpCenterPage(
      topics: topics,
      description: 'Find answers about rides, payments, location access, and your passenger account.',
      onBack: onBack ?? () => context.pop(),
    );
  }
}
