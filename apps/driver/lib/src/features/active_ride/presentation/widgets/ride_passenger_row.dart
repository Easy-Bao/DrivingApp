import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class const RidePassengerRow({
  super.key,
  required this.name,
  required this.subtitle,
  required this.unreadCount,
  required this.onCall,
  required this.onChat,
}) extends StatelessWidget {
  final String name;
  final String subtitle;
  final int unreadCount;
  final VoidCallback onCall;
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: context.colorScheme.surfaceContainerHighest,
          foregroundColor: context.colorScheme.onSurface,
          child: const Icon(LucideIcons.user_round, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: context.textStyles.titleSmall),
              Text(
                subtitle,
                style: context.textStyles.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Call passenger',
          onPressed: onCall,
          icon: const Icon(LucideIcons.phone, size: 20),
        ),
        const SizedBox(width: 8),
        Badge(
          isLabelVisible: unreadCount > 0,
          label: Text('$unreadCount'),
          child: IconButton.filledTonal(
            tooltip: 'Chat with passenger',
            onPressed: onChat,
            icon: const Icon(LucideIcons.message_circle, size: 20),
          ),
        ),
      ],
    );
  }
}
