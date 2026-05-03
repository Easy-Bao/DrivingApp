import "package:flutter/material.dart";
import "package:BaoRide/core/themes/app_themes.dart";
import "package:flutter_lucide/flutter_lucide.dart";

class PassengerAccountScreen extends StatelessWidget {
  const PassengerAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Account",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryColor,
                        letterSpacing: -1.5,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.settings,
                        color: AppTheme.primaryColor,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildProfileHeader(),
              const SizedBox(height: 40),
              _buildSectionTitle("Activity"),
              _buildAccountTile(
                LucideIcons.history,
                "Ride History",
                "View your past trips",
              ),
              _buildAccountTile(
                LucideIcons.wallet,
                "Payments",
                "Manage cards and credits",
              ),
              const SizedBox(height: 32),
              _buildSectionTitle("Personal"),
              _buildAccountTile(
                LucideIcons.user,
                "Profile Info",
                "Update name and details",
              ),
              _buildAccountTile(
                LucideIcons.shield_check,
                "Security",
                "Password and biometric",
              ),
              const SizedBox(height: 32),
              _buildSectionTitle("Support"),
              _buildAccountTile(
                LucideIcons.message_circle_question_mark,
                "Help Center",
                "Get support and FAQs",
              ),
              _buildAccountTile(
                LucideIcons.info,
                "About BaoRide",
                "Version 1.0.0",
              ),
              const SizedBox(height: 40),
              _buildLogoutButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppTheme.neutralColor,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.borderSide, width: 2),
            ),
            child: const Icon(
              LucideIcons.user,
              size: 50,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Xyrel Tenefrancia", // Based on your summary
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "+63 912 345 6789",
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: AppTheme.primaryColor.withValues(alpha: 0.4),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildAccountTile(IconData icon, String title, String subtitle) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: AppTheme.primaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.primaryColor.withValues(alpha: 0.5),
          fontSize: 13,
        ),
      ),
      trailing: const Icon(
        LucideIcons.chevron_right,
        size: 18,
        color: AppTheme.borderSide,
      ),
      onTap: () {},
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          foregroundColor: Colors.redAccent,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.log_out, size: 18),
            SizedBox(width: 10),
            Text(
              "Log Out",
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
