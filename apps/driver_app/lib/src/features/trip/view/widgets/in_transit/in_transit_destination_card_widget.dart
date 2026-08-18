import 'package:driver_app/src/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class InTransitDestinationCardWidget extends StatelessWidget {
  final String dropoffAddress;

  const InTransitDestinationCardWidget({
    super.key,
    required this.dropoffAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.neutralColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderSide),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.map_pin,
                size: 16,
                color: AppTheme.tertiaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  dropoffAddress,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'To destination',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.tertiaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
