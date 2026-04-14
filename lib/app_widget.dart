import 'package:flutter/material.dart';
import 'package:go_router_modular/go_router_modular.dart';
// import 'package:google_fonts/google_fonts.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ModularApp.router(
      theme: ThemeData(
        useMaterial3: true,
        textTheme: Theme.of(context).textTheme.apply(fontFamily: 'ProductSans'),
      ),
      debugShowCheckedModeBanner: false,
      title: 'BaoRide',
    );
  }
}
