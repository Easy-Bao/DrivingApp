import 'package:flutter/material.dart';

class QuickActionModel {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  QuickActionModel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
