import 'package:BaoRide/features/passenger/presentation/views/home/models/add_category_model.dart';
import 'package:flutter/material.dart';
import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

// TODO: Add location selection and icon Picker in the future for a more complete experience.
// TODO: Add validation and error handling for empty labels or invalid inputs.
//TODO: Add pinning location to the map and setting up the onTap callback to navigate to the pinned location when the shortcut is tapped.
class PassengerAddCategoryScreen extends StatefulWidget {
  final Function(AddCategoryModel) onSave;

  const PassengerAddCategoryScreen({super.key, required this.onSave});

  @override
  State<PassengerAddCategoryScreen> createState() =>
      _PassengerAddCategoryScreenState();
}

class _PassengerAddCategoryScreenState
    extends State<PassengerAddCategoryScreen> {
  final TextEditingController _controller = TextEditingController();
  IconData selectedIcon = LucideIcons.map_pin;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_controller.text.trim().isNotEmpty) {
      final newShortcut = AddCategoryModel(
        icon: selectedIcon,
        label: _controller.text.trim(),
        onTap: () {},
      );

      widget.onSave(newShortcut);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.chevron_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          "Add Shortcut",
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Label Your Shortcut",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.primaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Give this place a name like 'Gym' or 'Library'.",
              style: TextStyle(
                color: AppTheme.primaryColor.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              autofocus: true,
              style: const TextStyle(color: AppTheme.primaryColor),
              decoration: InputDecoration(
                hintText: "Enter label...",
                prefixIcon: Icon(selectedIcon, color: AppTheme.primaryColor),
                filled: true,
                fillColor: AppTheme.neutralColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.borderSide),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppTheme.borderSide),
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Save Shortcut",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
