import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

enum AppStatusBannerTone { warning, error }

/// Places a transient app status on the system edge instead of inside page
/// content, so the message remains visible without changing page layout.
class const AppStatusBanner({
  super.key,
  required this.isVisible,
  required this.message,
  required this.tone,
  this.actionLabel,
  this.onAction,
}) extends StatelessWidget {
  final bool isVisible;
  final String message;
  final AppStatusBannerTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final isError = tone == AppStatusBannerTone.error;
    final backgroundColor = isError
        ? scheme.errorContainer
        : scheme.tertiaryContainer;
    final foregroundColor = isError
        ? scheme.onErrorContainer
        : scheme.onTertiaryContainer;
    final canAct = actionLabel != null && onAction != null;

    final banner = Material(
      color: backgroundColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Semantics(
            container: true,
            liveRegion: true,
            label: message,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isError ? LucideIcons.circle_alert : Icons.cloud_off_outlined,
                  size: 18,
                  color: foregroundColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    textAlign: canAct ? TextAlign.start : TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: foregroundColor),
                  ),
                ),
                if (canAct) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onAction,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      foregroundColor: foregroundColor,
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    child: Text(actionLabel!),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    final statusSurface = canAct
        ? banner
        : IgnorePointer(child: banner);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: backgroundColor,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        child: statusSurface,
      ),
    );
  }
}
