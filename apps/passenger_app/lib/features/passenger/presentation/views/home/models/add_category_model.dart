import 'package:flutter/material.dart';

class AddCategoryModel {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  AddCategoryModel({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}
