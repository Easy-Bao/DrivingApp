import 'dart:async';

import 'package:design_system/src/theme/theme_context.dart';
import 'package:design_system/src/tokens/spacing.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:foundation/foundation.dart';
import 'package:material_ui/material_ui.dart';

class AppNetworkStatusScope extends InheritedWidget {
  const AppNetworkStatusScope({
    super.key,
    required this.isUnavailable,
    required super.child,
  });

  final bool isUnavailable;

  static bool isUnavailableOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppNetworkStatusScope>()
            ?.isUnavailable ??
        false;
  }

  @override
  bool updateShouldNotify(AppNetworkStatusScope oldWidget) {
    return isUnavailable != oldWidget.isUnavailable;
  }
}

/// Bridges [NetworkAvailabilityCoordinator] updates into [AppNetworkStatusScope]
/// and renders a global connectivity banner when the network or backend service
/// is unavailable without remounting [child].
class AppNetworkStatusHost extends StatefulWidget {
  const AppNetworkStatusHost({
    super.key,
    required this.coordinator,
    required this.child,
  });

  final NetworkAvailabilityCoordinator coordinator;
  final Widget child;

  @override
  State<AppNetworkStatusHost> createState() => _AppNetworkStatusHostState();
}

class _AppNetworkStatusHostState extends State<AppNetworkStatusHost> {
  late NetworkAvailabilityStatus _status;
  StreamSubscription<NetworkAvailabilityStatus>? _subscription;

  @override
  void initState() {
    super.initState();
    _status = widget.coordinator.status;
    _subscribe(widget.coordinator);
  }

  @override
  void didUpdateWidget(covariant AppNetworkStatusHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.coordinator, widget.coordinator)) {
      unawaited(_subscription?.cancel());
      _status = widget.coordinator.status;
      _subscribe(widget.coordinator);
    }
  }

  void _subscribe(NetworkAvailabilityCoordinator coordinator) {
    _subscription = coordinator.changes.listen((status) {
      if (!mounted || status == _status) return;
      setState(() => _status = status);
    });
  }

  @override
  void dispose() {
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final showBanner = _status.hasAvailabilityWarning;
    return AppNetworkStatusScope(
      isUnavailable: _status.isConnectionUnavailable,
      child: Column(
        children: [
          if (showBanner)
            _AppNetworkStatusBanner(status: _status)
          else
            const SizedBox.shrink(),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: showBanner,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppNetworkStatusBanner extends StatelessWidget {
  const _AppNetworkStatusBanner({required this.status});

  final NetworkAvailabilityStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final isOffline = status.isConnectionUnavailable;
    final message = isOffline
        ? 'No internet connection. Reconnecting automatically...'
        : 'Service temporarily unavailable. Retrying automatically...';
    final backgroundColor = isOffline
        ? colorScheme.errorContainer
        : colorScheme.inverseSurface;
    final foregroundColor = isOffline
        ? colorScheme.onErrorContainer
        : colorScheme.onInverseSurface;

    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: Material(
        key: const ValueKey<String>('app-network-status-banner'),
        color: backgroundColor,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    isOffline ? LucideIcons.wifi_off : LucideIcons.circle_alert,
                    size: 16,
                    color: foregroundColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.labelMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
