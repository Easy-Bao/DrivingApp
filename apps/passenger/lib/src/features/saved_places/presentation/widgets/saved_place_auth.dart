import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger/src/features/auth/auth_routes.dart';
import 'package:passenger/src/features/auth/presentation/bloc/session/session_bloc.dart';
import 'package:passenger/src/features/booking/presentation/widgets/booking_auth_bottom_sheet.dart';

Future<bool> ensureSavedPlaceAuthentication(BuildContext context) async {
  if (BlocProvider.of<SessionBloc>(context).state.isAuthenticated) return true;

  final action = await showBookingAuthBottomSheet(
    context,
    title: 'Sign in to save places',
    message: 'Sign in or create an account to save home, work, and favourite places for your next ride.',
  );
  if (!context.mounted || action == null) return false;
  final route = switch (action) {
    BookingAuthAction.signIn => AuthRoutes.signin,
    BookingAuthAction.signUp => AuthRoutes.signup,
  };
  unawaited(context.pushNamed(route));
  return false;
}
