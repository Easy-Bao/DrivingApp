import 'package:flutter/material.dart';
import 'package:passenger/src/features/ride_history/presentation/view/ride_history_page.dart';

class const RecentActivityPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const RideHistoryPage(
      title: 'Recent activity',
      showBackButton: true,
      showHeaderSubtitle: false,
      showSummary: false,
      showFilters: false,
    );
  }
}
