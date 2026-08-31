import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_cubit.dart';
import 'package:driver_app/src/features/trip/presentation/bloc/ride_flow/ride_flow_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:shared_ui/shared_ui.dart';

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
        color: context.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: context.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.user,
              color: context.colorScheme.onSurface,
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
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Passenger Onboard',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.user_round,
            size: 16,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
