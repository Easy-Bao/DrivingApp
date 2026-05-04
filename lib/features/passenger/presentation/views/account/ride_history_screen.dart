import "package:BaoRide/core/models/ride_history_model.dart";
import "package:BaoRide/core/themes/app_themes.dart";
import "package:flutter/material.dart";
import "package:flutter_lucide/flutter_lucide.dart";
import "package:go_router_modular/go_router_modular.dart";

class RideHistoryScreen extends StatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  State<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends State<RideHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<RideHistoryModel> _rides = [
    RideHistoryModel(id: "1", pickup: "Brgy. Balangasan", destination: "Robinson Supermarket",
      pickupLat: 7.8307, pickupLng: 123.4370, destLat: 7.8250, destLng: 123.4380,
      date: "MAY 02, 09:15 AM", price: "₱32.50", status: "completed", driverName: "Juan dela Cruz", vehiclePlate: "ABC 1234"),
    RideHistoryModel(id: "2", pickup: "San Francisco St.", destination: "Pagadian City Science HS",
      pickupLat: 7.8310, pickupLng: 123.4375, destLat: 7.8280, destLng: 123.4390,
      date: "MAY 01, 07:30 AM", price: "₱28.00", status: "completed", driverName: "Pedro Santos", vehiclePlate: "XYZ 5678"),
    RideHistoryModel(id: "3", pickup: "Plaza Luz", destination: "Gaisano Capital",
      pickupLat: 7.8290, pickupLng: 123.4365, destLat: 7.8260, destLng: 123.4355,
      date: "APR 30, 02:00 PM", price: "₱18.50", status: "canceled", driverName: "", vehiclePlate: ""),
    RideHistoryModel(id: "4", pickup: "Bo's Coffee", destination: "Tuburan District",
      pickupLat: 7.8300, pickupLng: 123.4360, destLat: 7.8200, destLng: 123.4340,
      date: "APR 29, 11:45 AM", price: "₱45.00", status: "completed", driverName: "Maria Garcia", vehiclePlate: "DEF 9012"),
    RideHistoryModel(id: "5", pickup: "Balangasan", destination: "Robinson Supermarket",
      pickupLat: 7.8307, pickupLng: 123.4370, destLat: 7.8250, destLng: 123.4380,
      date: "APR 28, 08:00 AM", price: "₱32.50", status: "completed", driverName: "Juan dela Cruz", vehiclePlate: "ABC 1234"),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<RideHistoryModel> _filteredRides(int tabIndex) {
    if (tabIndex == 0) return _rides;
    if (tabIndex == 1) return _rides.where((r) => r.status == "completed").toList();
    return _rides.where((r) => r.status == "canceled").toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface, elevation: 0, scrolledUnderElevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrow_left, color: AppTheme.primaryColor), onPressed: () => context.pop()),
        title: const Text("Ride History", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 50, padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppTheme.outlineBorderColor, borderRadius: BorderRadius.circular(26)),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(color: AppTheme.neutralColor, borderRadius: BorderRadius.circular(22)),
                labelColor: AppTheme.selectedItemColor,
                unselectedLabelColor: AppTheme.unselectedItemColor,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: const [Tab(text: "All"), Tab(text: "Completed"), Tab(text: "Canceled")],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(3, (i) {
                final rides = _filteredRides(i);
                if (rides.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(LucideIcons.history, size: 40, color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                    const SizedBox(height: 12),
                    Text("No rides yet", style: TextStyle(color: AppTheme.primaryColor.withValues(alpha: 0.4), fontWeight: FontWeight.w600)),
                  ]));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: rides.length,
                  itemBuilder: (ctx, idx) => _buildRideCard(rides[idx]),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(RideHistoryModel ride) {
    Color statusBg = ride.status == "completed"
        ? AppTheme.complete.withValues(alpha: 0.5)
        : AppTheme.cancel;

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
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(ride.date, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.unselectedItemColor)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10)),
              child: Text(ride.status.toUpperCase(),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.surface)),
            ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Column(children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle)),
              Container(width: 1, height: 20, color: AppTheme.outlineBorderColor),
              const Icon(Icons.location_on, size: 14, color: AppTheme.tertiaryColor),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ride.pickup, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
              const SizedBox(height: 8),
              Text(ride.destination, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
            ])),
            Text(ride.price, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
          ]),
          if (ride.driverName.isNotEmpty) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1, color: AppTheme.borderSide)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                const Icon(Icons.directions_car, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(ride.driverName, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor.withValues(alpha: 0.6))),
              ]),
              Text(ride.vehiclePlate, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor.withValues(alpha: 0.5))),
            ]),
          ],
        ],
      ),
    );
  }
}
