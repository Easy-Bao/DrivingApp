import 'package:flutter/material.dart';
import 'package:BaoRide/core/themes/app_themes.dart';

class PassengerActivityScreen extends StatefulWidget {
  const PassengerActivityScreen({super.key});

  @override
  State<PassengerActivityScreen> createState() =>
      _PassengerActivityScreenState();
}

class _PassengerActivityScreenState extends State<PassengerActivityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 54,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.outlineBorderColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppTheme.neutralColor,
                    borderRadius: BorderRadius.circular(26),
                  ),
                  labelColor: AppTheme.selectedItemColor,
                  unselectedLabelColor: AppTheme.unselectedItemColor,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: "Past"),
                    Tab(text: "Upcoming"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildActivityCard(
                        date: "OCT 24, 08:30 AM",
                        location: "Pagadian Science High School",
                        address: "Tuburan District",
                        price: "₱32.50",
                        status: "COMPLETED",
                        statusType: "completed",
                      ),
                      _buildActivityCard(
                        date: "OCT 24, 08:30 AM",
                        location: "Pagadian Science High School",
                        address: "Tuburan District",
                        price: "₱32.50",
                        status: "CANCELED",
                        statusType: "canceled",
                      ),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildActivityCard(
                        date: "OCT 25, 10:00 AM",
                        location: "City Commercial Center",
                        address: "Rizal Avenue",
                        price: "₱45.00",
                        status: "IN PROGRESS",
                        statusType: "progress",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard({
    required String date,
    required String location,
    required String address,
    required String price,
    required String status,
    required String statusType,
  }) {
    Color getStatusBg() {
      if (statusType == "completed") {
        return AppTheme.complete.withValues(alpha: 0.5);
      }
      if (statusType == "progress") return AppTheme.inProgress;
      return AppTheme.cancel;
    }

    Color getStatusText() {
      if (statusType == "canceled") return AppTheme.surface;
      if (statusType == "progress") return AppTheme.surface;
      return AppTheme.primaryColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outlineBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                date,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.unselectedItemColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: getStatusBg(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: getStatusText(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            location,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address,
                      style: TextStyle(
                        color: AppTheme.unselectedItemColor,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppTheme.borderSide),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.directions_car,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              Text(
                statusType == "progress"
                    ? "Track Driver"
                    : (statusType == "completed" ? "View Details" : "Rebook"),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
