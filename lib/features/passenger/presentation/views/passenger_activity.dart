import 'package:flutter/material.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:go_router_modular/go_router_modular.dart';

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
      appBar: AppBar(
        title: Text("Activity", style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
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
                        pickup: "Brgy. Balangasan",
                        destination: "Robinson Supermarket",
                        price: "₱32.50",
                        status: "COMPLETED",
                        statusType: "completed",
                      ),
                      _buildActivityCard(
                        date: "OCT 24, 08:30 AM",
                        pickup: "San Francisco St.",
                        destination: "Pagadian City Science High School",
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
                        pickup: "Balangasan",
                        destination: "Tuburan District",
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
    required String pickup,
    required String destination,
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
      return AppTheme.surface;
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
          const SizedBox(height: 12),
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: AppTheme.outlineBorderColor,
                  ),
                  const Icon(
                    Icons.location_on,
                    size: 14,
                    color: AppTheme.tertiaryColor,
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickup,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      destination,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
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
              TextButton(
                onPressed: () {
                  if (statusType == "progress") {
                    context.pushNamed("ActivityTrackDriver");
                  } else if (statusType == "completed") {
                    context.pushNamed("ActivityViewDetails");
                  } else {
                    //TODO: Implement Rebook Navigation
                  }
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  statusType == "progress"
                      ? "Track Driver"
                      : (statusType == "completed" ? "View Details" : "Rebook"),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
