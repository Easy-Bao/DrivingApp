import 'package:BaoRide/core/themes/app_themes.dart';
import 'package:BaoRide/features/passenger/presentation/views/home/models/add_category_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';

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
  String? _errorMessage;
  bool _isLocationPinned = false;

  final List<IconData> _availableIcons = [
    LucideIcons.map_pin,
    LucideIcons.house,
    LucideIcons.briefcase,
    LucideIcons.shopping_cart,
    LucideIcons.heart,
    LucideIcons.star,
    LucideIcons.coffee,
    LucideIcons.dumbbell,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSave() {
    final label = _controller.text.trim();

    if (label.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a name for your shortcut.';
      });
      return;
    }

    if (!_isLocationPinned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pin a location on the map before saving.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _errorMessage = null;
    });

    final newShortcut = AddCategoryModel(
      icon: selectedIcon,
      label: label,
      onTap: () {
        context.push('/map-navigation', extra: {'destination': label});
      },
    );

    widget.onSave(newShortcut);
    context.pop();
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
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Add Shortcut',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Label Your Shortcut',
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
                    autofocus: false,
                    style: const TextStyle(color: AppTheme.primaryColor),
                    onChanged: (value) {
                      if (_errorMessage != null) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Enter label...',
                      errorText: _errorMessage,
                      prefixIcon: Icon(
                        selectedIcon,
                        color: AppTheme.primaryColor,
                      ),
                      filled: true,
                      fillColor: AppTheme.neutralColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.borderSide,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.borderSide,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Select Icon',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _availableIcons.map((icon) {
                      final isSelected = selectedIcon == icon;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedIcon = icon;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : AppTheme.neutralColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : AppTheme.borderSide,
                            ),
                          ),
                          child: Icon(
                            icon,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.primaryColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Pin Location',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isLocationPinned = !_isLocationPinned;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.neutralColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isLocationPinned
                              ? Colors.green
                              : AppTheme.borderSide,
                          width: _isLocationPinned ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isLocationPinned
                                  ? LucideIcons.map_pin
                                  : LucideIcons.map,
                              size: 48,
                              color: _isLocationPinned
                                  ? Colors.green
                                  : AppTheme.primaryColor.withValues(
                                      alpha: 0.4,
                                    ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isLocationPinned
                                  ? '✓ Location Pinned Successfully'
                                  : 'Tap to pin your location on the map',
                              style: TextStyle(
                                color: _isLocationPinned
                                    ? Colors.green
                                    : AppTheme.primaryColor.withValues(
                                        alpha: 0.6,
                                      ),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            if (!_isLocationPinned) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Select a spot to save this shortcut',
                                style: TextStyle(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.4,
                                  ),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                bottom: 24.0,
                top: 12.0,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save Shortcut',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
