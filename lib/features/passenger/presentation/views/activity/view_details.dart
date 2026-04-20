import 'package:flutter/material.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

class ActivityViewDetails extends StatefulWidget {
  const ActivityViewDetails({super.key});

  @override
  State<ActivityViewDetails> createState() => _ActivityViewDetailsState();
}

class _ActivityViewDetailsState extends State<ActivityViewDetails> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Trip Details",
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.outlineBorderColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.map_outlined,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.secondaryColor,
                  child: const Icon(Icons.person, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Xyrel D. Tenefrancia",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      Text(
                        "Bao Bao",
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.tertiaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.star, color: AppTheme.primaryColor, size: 16),
                const Text(
                  " 4.9",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: AppTheme.outlineBorderColor),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.outlineBorderColor),
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    spacing: 10,
                    children: [
                      Text(
                        "Fare Summary",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        "₱32.50",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _fareRow("Base Fare", "₱5.50"),
                  _fareRow("Distance", "₱24.80"),
                  _fareRow("Fees", "₱2.20"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Timeline",
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 16),
                _timelineItem("Balangasan", "10:14 AM", true),
                _timelineItem("Tuburan District", "10:38 AM", false),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh),
              label: const Text(
                "Book this route again",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fareRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppTheme.unselectedItemColor, fontSize: 13),
        ),
        Text(
          amount,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    );
  }

  Widget _timelineItem(String loc, String time, bool isTop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isTop ? Icons.circle : Icons.location_on,
              size: 16,
              color: AppTheme.primaryColor,
            ),
            if (isTop)
              Container(
                width: 2,
                height: 30,
                color: AppTheme.outlineBorderColor,
              ),
          ],
        ),
        const SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.unselectedItemColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
