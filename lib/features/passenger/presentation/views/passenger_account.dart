import "package:flutter/material.dart";

class PassengerAccountScreen extends StatefulWidget {
  const PassengerAccountScreen({super.key});

  @override
  State<PassengerAccountScreen> createState() => _PassengerAccountScreenState();
}

class _PassengerAccountScreenState extends State<PassengerAccountScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(child: Text("PassengerAccountScreen"))),
    );
  }
}
