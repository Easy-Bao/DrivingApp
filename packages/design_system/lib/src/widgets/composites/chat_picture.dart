import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Displays a participant-authorized picture without exposing storage URLs.
class ChatPicture extends StatefulWidget {
  const ChatPicture({super.key, required this.load});

  final Future<Uint8List> Function() load;

  @override
  State<ChatPicture> createState() => _ChatPictureState();
}

class _ChatPictureState extends State<ChatPicture> {
  late Future<Uint8List> _picture = widget.load();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 180,
      child: FutureBuilder<Uint8List>(
        future: _picture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton.icon(
                onPressed: () => setState(() => _picture = widget.load()),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry picture'),
              ),
            );
          }
          final bytes = snapshot.data;
          if (bytes == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Semantics(
            label: 'Picture. Tap to enlarge',
            button: true,
            child: InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (context) => Dialog.fullscreen(
                  child: Scaffold(
                    appBar: AppBar(title: const Text('Picture')),
                    body: Center(
                      child: InteractiveViewer(
                        maxScale: 5,
                        child: Image.memory(bytes, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
              ),
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                cacheWidth: 660,
                errorBuilder: (_, _, _) =>
                    const Center(child: Text('Picture unavailable')),
              ),
            ),
          );
        },
      ),
    );
  }
}

class const ChatPeerHeader({super.key, required this.name, this.subtitle = ''})
    extends StatelessWidget {
  final String name;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          foregroundColor: theme.colorScheme.onSurface,
          child: Text(
            name.trim().isEmpty
                ? '?'
                : name.trim().characters.first.toUpperCase(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
