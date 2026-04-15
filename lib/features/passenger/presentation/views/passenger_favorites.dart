import "package:BaoRide/core/themes/app_themes.dart";
import "package:flutter/material.dart";

class PassengerFavoritesScreen extends StatefulWidget {
  const PassengerFavoritesScreen({super.key});

  @override
  State<PassengerFavoritesScreen> createState() =>
      _PassengerFavoritesScreenState();
}

class _PassengerFavoritesScreenState extends State<PassengerFavoritesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(child: Center(child: Text("PassengerFavoritesScreen"))),
    );
  }
}
