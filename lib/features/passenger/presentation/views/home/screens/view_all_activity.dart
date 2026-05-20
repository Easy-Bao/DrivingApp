import "package:BaoRide/core/themes/app_themes.dart";
import "package:flutter/material.dart";
import "package:flutter_lucide/flutter_lucide.dart";
import "package:go_router_modular/go_router_modular.dart";

class PassengerViewAllActivity extends StatefulWidget {
  const PassengerViewAllActivity({super.key});

  @override
  State<PassengerViewAllActivity> createState() =>
      _PassengerViewAllActivityState();
}

class _PassengerViewAllActivityState extends State<PassengerViewAllActivity> {
  final Map<String, List<Map<String, String>>> _grouped = {
    "Today": [
      {
        "pickup": "Brgy. Balangasan",
        "dest": "Robinson Supermarket",
        "time": "09:15 AM",
        "price": "₱32.50",
        "status": "completed",
      },
    ],
    "Yesterday": [
      {
        "pickup": "San Francisco St.",
        "dest": "Pagadian City Science HS",
        "time": "07:30 AM",
        "price": "₱28.00",
        "status": "canceled",
      },
      {
        "pickup": "Plaza Luz",
        "dest": "Bo's Coffee",
        "time": "02:00 PM",
        "price": "₱15.00",
        "status": "completed",
      },
    ],
    "Apr 30": [
      {
        "pickup": "Gaisano Capital",
        "dest": "Tuburan District",
        "time": "11:45 AM",
        "price": "₱45.00",
        "status": "completed",
      },
    ],
    "Apr 29": [
      {
        "pickup": "Balangasan",
        "dest": "Robinson Supermarket",
        "time": "08:00 AM",
        "price": "₱32.50",
        "status": "completed",
      },
      {
        "pickup": "Bo's Coffee",
        "dest": "Plaza Luz",
        "time": "04:30 PM",
        "price": "₱12.00",
        "status": "completed",
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Recent Activity",
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        physics: const BouncingScrollPhysics(),
        itemCount: _grouped.keys.length,
        itemBuilder: (context, sectionIndex) {
          final dateKey = _grouped.keys.elementAt(sectionIndex);
          final items = _grouped[dateKey]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                child: Text(
                  dateKey.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ...items.map((item) => _buildActivityCard(item)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActivityCard(Map<String, String> item) {
    final isCompleted = item["status"] == "completed";
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outlineBorderColor),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item["time"]!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.unselectedItemColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppTheme.complete.withValues(alpha: 0.5)
                      : AppTheme.cancel,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item["status"]!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.surface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 18,
                    color: AppTheme.outlineBorderColor,
                  ),
                  const Icon(
                    Icons.location_on,
                    size: 12,
                    color: AppTheme.tertiaryColor,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item["pickup"]!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item["dest"]!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item["price"]!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppTheme.borderSide),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(
                Icons.directions_car,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              TextButton(
                onPressed: () {
                  if (isCompleted) context.pushNamed("ActivityViewDetails");
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  isCompleted ? "View Details" : "Rebook",
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
