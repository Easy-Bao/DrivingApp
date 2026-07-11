import 'package:flutter/material.dart';

class LocationSuggestionModel {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  LocationSuggestionModel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
