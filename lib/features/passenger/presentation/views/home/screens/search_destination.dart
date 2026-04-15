import "dart:developer";

import "package:BaoRide/core/themes/app_themes.dart";
import "package:flutter/material.dart";
import "package:flutter_lucide/flutter_lucide.dart";

class SearchDestinationScreen extends StatefulWidget {
  const SearchDestinationScreen({super.key});

  @override
  State<SearchDestinationScreen> createState() =>
      _SearchDestinationScreenState();
}

class _SearchDestinationScreenState extends State<SearchDestinationScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Hero(
            tag: 'search_bar_field',
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neutralColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.search,
                      color: AppTheme.primaryColor.withValues(alpha: 0.6),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppTheme.primaryColor,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search destination",
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: AppTheme.primaryColor.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    ),
                    GestureDetector(
                      onTap: () {
                        //TODO: Action for "Set on Map"
                        debugPrint("Clicked");
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.map_pin,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Pin",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: const Column(
        children: [
          Divider(height: 1, color: AppTheme.borderSide),
          Expanded(
            child: Center(
              child: Text(
                "Search results will appear here",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
