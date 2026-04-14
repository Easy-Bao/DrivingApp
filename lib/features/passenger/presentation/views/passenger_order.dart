import "package:flutter/material.dart";

class PassengerOrderScreen extends StatefulWidget {
  const PassengerOrderScreen({super.key});

  @override
  State<PassengerOrderScreen> createState() => _PassengerOrderScreenState();
}

class _PassengerOrderScreenState extends State<PassengerOrderScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: Center(child: Text("PassengerOrderScreen"))),
    );
  }
}
