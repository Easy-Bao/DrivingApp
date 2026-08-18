import 'package:driver_app/src/core/theme/app_theme.dart';

import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/bloc/ride_flow/ride_flow_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class InTransitPassengerCardWidget extends StatelessWidget {
  const InTransitPassengerCardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final state = BlocProvider.of<RideFlowCubit>(context).state;
    final passengerName = state is RideFlowInTransit
        ? state.passengerName
        : 'Passenger';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppTheme.secondarySurface,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.user,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passengerName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const Text(
                  'Passenger onboard',
                  style: TextStyle(fontSize: 11, color: AppTheme.tertiaryColor),
                ),
              ],
            ),
          ),
          const Icon(
            LucideIcons.user_round,
            size: 16,
            color: AppTheme.tertiaryColor,
          ),
        ],
      ),
    );
  }
}
