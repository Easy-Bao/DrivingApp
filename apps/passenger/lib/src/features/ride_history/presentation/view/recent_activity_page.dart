import 'package:flutter/material.dart';
import 'package:passenger/src/features/ride_history/presentation/view/ride_history_page.dart';

/// Full recent-activity history opened from the Home page.
class const RecentActivityPage({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const RideHistoryPage(
      title: 'Recent Activity',
      subtitle: 'Your latest rides',
      showSummary: false,
      showFilters: false,
    );
  }
}
