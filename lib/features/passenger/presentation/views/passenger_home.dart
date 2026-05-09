import "package:BaoRide/core/themes/app_themes.dart";
import "package:BaoRide/features/passenger/presentation/views/home/models/add_category_model.dart";
import "package:BaoRide/features/passenger/presentation/views/home/models/quick_action_model.dart";
import "package:flutter/material.dart";
import "package:flutter_lucide/flutter_lucide.dart";
import "package:go_router_modular/go_router_modular.dart";

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  final List<QuickActionModel> quickActions = [
    QuickActionModel(
      icon: LucideIcons.bike,
      title: "Solo Ride",
      subtitle: "Direct booking",
      onTap: () {},
    ),
    QuickActionModel(
      icon: LucideIcons.users,
      title: "Share-Bao",
      subtitle: "Pasabay",
      onTap: () {},
    ),
  ];

  final List<Map<String, dynamic>> recentLocationData = [
    {
      "icon": LucideIcons.circle_play,
      "title": "Plaza Luz",
      "subtitle": "San Francisco",
      "lat": 7.8275,
      "lng": 123.4365,
    },
    {
      "icon": LucideIcons.store,
      "title": "Robinson Supermarket",
      "subtitle": "San Francisco",
      "lat": 7.8250,
      "lng": 123.4380,
    },
    {
      "icon": LucideIcons.coffee,
      "title": "Bo's Coffee",
      "subtitle": "San Francisco",
      "lat": 7.8295,
      "lng": 123.4358,
    },
    {
      "icon": LucideIcons.shopping_bag,
      "title": "Gaisano Capital",
      "subtitle": "San Francisco",
      "lat": 7.8260,
      "lng": 123.4355,
    },
  ];

  List<AddCategoryModel> shortcuts = [];

  @override
  void initState() {
    super.initState();
    shortcuts = [
      AddCategoryModel(
        icon: LucideIcons.house,
        label: "Home",
        onTap: () => _showFeedback("Home tapped"),
      ),
      AddCategoryModel(
        icon: LucideIcons.graduation_cap,
        label: "Campus",
        onTap: () => _showFeedback("Campus tapped"),
      ),
      AddCategoryModel(
        icon: LucideIcons.briefcase,
        label: "Work",
        onTap: () => _showFeedback("Work tapped"),
      ),
    ];
  }

  void _showFeedback(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openAddCategoryScreen() {
    context.pushNamed(
      "PassengerAddCategory",
      extra: (AddCategoryModel newShortcut) {
        setState(() {
          shortcuts.add(
            AddCategoryModel(
              icon: newShortcut.icon,
              label: newShortcut.label,
              onTap: () => _showFeedback("${newShortcut.label} tapped"),
            ),
          );
        });
      },
    );
  }

  void _openActivityDetail(Map<String, dynamic> location) {
    context.pushNamed("ActivityDetailMap", extra: location);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "EasyRide",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                          letterSpacing: -1.5,
                        ),
                      ),
                      Text(
                        "Ready to ride today?",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            LucideIcons.bell,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: () => context.pushNamed("Notifications"),
                        ),
                      ),
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(
                    LucideIcons.map_pin,
                    size: 14,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    "Pagadian City, Zamboanga del Sur",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => context.pushNamed("SearchDestination"),
                      child: Hero(
                        tag: 'search_bar_field',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.neutralColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderSide),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.search,
                                  color: AppTheme.primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  "Enter destination",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.6,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _showFeedback("Locating..."),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        LucideIcons.locate_fixed,
                        color: AppTheme.neutralColor,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    ...shortcuts.map(
                      (shortcut) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: shortcut.onTap,
                          child: _buildShortcutChip(
                            shortcut.icon,
                            shortcut.label,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _openAddCategoryScreen,
                      child: _buildShortcutChip(LucideIcons.plus, "Add"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: quickActions.asMap().entries.map((entry) {
                  final isLast = entry.key == quickActions.length - 1;
                  final action = entry.value;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: isLast ? 0 : 12),
                      child: _buildQuickActionCard(
                        icon: action.icon,
                        title: action.title,
                        subtitle: action.subtitle,
                        onTap: () => _showFeedback(action.title),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Activity",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.pushNamed("ViewAllSuggestions"),
                    child: const Text(
                      "View all",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: recentLocationData.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: Colors.grey[100]),
                  itemBuilder: (context, index) {
                    final location = recentLocationData[index];
                    return _buildLocationItem(
                      icon: location["icon"] as IconData,
                      title: location["title"] as String,
                      subtitle: location["subtitle"] as String,
                      onTap: () => _openActivityDetail(location),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border.all(color: AppTheme.borderSide),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.primaryColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderSide),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 28),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppTheme.primaryColor,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
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
          fontSize: 15,
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
        size: 16,
        color: AppTheme.borderSide,
      ),
      onTap: onTap,
    );
  }
}
