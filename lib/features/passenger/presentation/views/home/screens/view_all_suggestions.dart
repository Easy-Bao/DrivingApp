import "package:BaoRide/core/themes/app_themes.dart";
import "package:flutter/material.dart";
import "package:flutter_lucide/flutter_lucide.dart";
import "package:go_router_modular/go_router_modular.dart";

class PassengerViewAllSuggestions extends StatefulWidget {
  const PassengerViewAllSuggestions({super.key});

  @override
  State<PassengerViewAllSuggestions> createState() =>
      _PassengerViewAllSuggestionsState();
}

class _PassengerViewAllSuggestionsState
    extends State<PassengerViewAllSuggestions> {
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
          "Recent Suggestions",
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
    );
  }
}
