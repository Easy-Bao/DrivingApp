import "package:BaoRide/core/themes/app_themes.dart";
import "package:BaoRide/features/passenger/presentation/views/home/models/location_suggestion_model.dart";
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

  final List<LocationSuggestionModel> recentLocations = [
    LocationSuggestionModel(
      icon: LucideIcons.circle_play,
      title: "Plaza Luz",
      subtitle: "San Francisco",
      onTap: () {},
    ),
    LocationSuggestionModel(
      icon: LucideIcons.store,
      title: "Robinson Supermarket",
      subtitle: "San Francisco",
      onTap: () {},
    ),
    LocationSuggestionModel(
      icon: LucideIcons.coffee,
      title: "Bo's Coffee",
      subtitle: "San Francisco",
      onTap: () {},
    ),
    LocationSuggestionModel(
      icon: LucideIcons.shopping_bag,
      title: "Gaisano Capital",
      subtitle: "San Francisco",
      onTap: () {},
    ),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                const SizedBox.expand(child: Center(child: Text("Map Here"))),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            LucideIcons.ellipsis_vertical,
                            color: AppTheme.primaryColor,
                          ),
                          onPressed: () => _showFeedback("Menu tapped"),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(width: 1, color: AppTheme.borderSide),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Where to?",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showFeedback("Locate me tapped"),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.locate_fixed,
                              color: AppTheme.neutralColor,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context.pushNamed("SearchDestination");
                            },
                            child: Hero(
                              tag: 'search_bar_field',
                              child: Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.neutralColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LucideIcons.search,
                                        color: AppTheme.primaryColor.withValues(
                                          alpha: 0.6,
                                        ),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        "Search destination",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppTheme.primaryColor
                                              .withValues(alpha: 0.6),
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _showFeedback("Schedule clock tapped"),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.neutralColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.clock,
                                  size: 24,
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "Schedule",
                                  style: TextStyle(
                                    color: AppTheme.primaryColor.withValues(
                                      alpha: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: quickActions
                          .asMap()
                          .entries
                          .map((entry) {
                            final int index = entry.key;
                            final action = entry.value;
                            final isLast = index == quickActions.length - 1;

                            final Widget card = Expanded(
                              child: _buildQuickActionCard(
                                icon: action.icon,
                                title: action.title,
                                subtitle: action.subtitle,
                                onTap: () {
                                  action.onTap();
                                  _showFeedback("${action.title} tapped");
                                },
                              ),
                            );

                            if (!isLast) {
                              return [card, const SizedBox(width: 12)];
                            }
                            return [card];
                          })
                          .expand((element) => element)
                          .toList(),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Recent Suggestions",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.pushNamed("ViewAllSuggestions"),
                          child: Text(
                            "See all",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: recentLocations.asMap().entries.map((
                            entry,
                          ) {
                            final int index = entry.key;
                            final location = entry.value;
                            final isLast = index == recentLocations.length - 1;

                            return Column(
                              children: [
                                _buildLocationItem(
                                  icon: location.icon,
                                  title: location.title,
                                  subtitle: location.subtitle,
                                  onTap: () {
                                    location.onTap();
                                    _showFeedback("${location.title} tapped");
                                  },
                                ),
                                if (!isLast)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 56),
                                    child: Divider(
                                      height: 1,
                                      color: Colors.grey[200],
                                    ),
                                  ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
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
        padding: const EdgeInsets.all(10),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AppTheme.primaryColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.primaryColor.withValues(alpha: 0.5),
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(
        LucideIcons.chevron_right,
        size: 18,
        color: AppTheme.primaryColor.withValues(alpha: 0.4),
      ),
      onTap: onTap,
    );
  }
}
