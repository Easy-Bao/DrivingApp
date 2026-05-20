import 'package:flutter/material.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class DriverTripHistoryScreen extends StatelessWidget {
  const DriverTripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Trip History",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        physics: const BouncingScrollPhysics(),
        children: [
          _sectionHeader("Today"),
          _tripCard(
            "SM City Dipolog",
            "Dipolog Market",
            "₱52.00",
            "8 min",
            "Completed",
            AppTheme.complete,
          ),
          _tripCard(
            "Turno, Dipolog",
            "Biasong, Dipolog",
            "₱38.00",
            "6 min",
            "Completed",
            AppTheme.complete,
          ),
          const SizedBox(height: 20),
          _sectionHeader("Yesterday"),
          _tripCard(
            "Galas, Dipolog",
            "Olingan, Dipolog",
            "₱65.00",
            "12 min",
            "Completed",
            AppTheme.complete,
          ),
          _tripCard(
            "Central, Dipolog",
            "Sicayab, Dipolog",
            "₱45.00",
            "9 min",
            "Completed",
            AppTheme.complete,
          ),
          _tripCard(
            "Miputak, Dipolog",
            "Airport Rd, Dipolog",
            "₱72.00",
            "15 min",
            "Canceled",
            AppTheme.cancel,
          ),
          const SizedBox(height: 20),
          _sectionHeader("May 17"),
          _tripCard(
            "Cogon Market",
            "Sta. Filomena",
            "₱55.00",
            "10 min",
            "Completed",
            AppTheme.complete,
          ),
          _tripCard(
            "Boulevard, Dipolog",
            "Sunset Blvd",
            "₱30.00",
            "5 min",
            "Completed",
            AppTheme.complete,
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppTheme.primaryColor.withValues(alpha: 0.4),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _tripCard(
    String from,
    String to,
    String fare,
    String time,
    String status,
    Color statusColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Row(
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
                height: 24,
                color: AppTheme.outlineBorderColor,
              ),
              Icon(Icons.location_on, size: 14, color: AppTheme.tertiaryColor),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  from,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  to,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fare,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
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
