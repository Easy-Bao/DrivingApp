import 'package:flutter/widgets.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

IconData savedPlaceIconFromName(String iconName) {
  switch (iconName) {
    case 'house':
      return LucideIcons.house;
    case 'graduation_cap':
      return LucideIcons.graduation_cap;
    case 'briefcase':
      return LucideIcons.briefcase;
    case 'heart':
      return LucideIcons.heart;
    case 'star':
      return LucideIcons.star;
    case 'coffee':
      return LucideIcons.coffee;
    case 'dumbbell':
      return LucideIcons.dumbbell;
    case 'shopping_cart':
      return LucideIcons.shopping_cart;
    case 'users':
      return LucideIcons.users;
    case 'store':
      return LucideIcons.store;
    case 'map_pin':
    default:
      return LucideIcons.map_pin;
  }
}
