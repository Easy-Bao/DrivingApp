import 'dart:async';

import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:maps/src/presentation/camera_service.dart';
import 'package:material_ui/material_ui.dart' hide Route;

class AppMapView extends StatefulWidget {
  const AppMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.styleUri,
    required this.onMapCreated,
    required this.onMapLoaded,
    required this.onCameraChanged,
    required this.onMapIdle,
    required this.interactive,
    required this.showUserLocation,
    this.zoom = 14.0,
    this.padding,
  });

  final double latitude;
  final double longitude;
  final double zoom;
  final String styleUri;
  final void Function(AppMapController controller)? onMapCreated;
  final VoidCallback? onMapLoaded;
  final void Function(AppMapController controller)? onCameraChanged;
  final void Function(AppMapController controller)? onMapIdle;
  final bool interactive;
  final bool showUserLocation;
  final EdgeInsets? padding;

  @override
  State<AppMapView> createState() => _AppMapViewState();
}

class _AppMapViewState extends State<AppMapView> {
  AppMapController? _mapController;
  bool _mapLoaded = false;
  bool _mapLoadFailed = false;
  bool _chromeHidden = false;
  (String, int)? _preparingMap;
  int _mapGeneration = 0;

  @override
  void didUpdateWidget(AppMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.styleUri != oldWidget.styleUri) {
      _mapController = null;
      _mapLoaded = false;
      _mapLoadFailed = false;
      _chromeHidden = false;
      _preparingMap = null;
      return;
    }

    final controller = _mapController;
    if (controller == null) return;
    if (widget.interactive != oldWidget.interactive) {
      unawaited(_applyGestureSettings(controller.native, widget.interactive));
    }
    if (widget.showUserLocation != oldWidget.showUserLocation) {
      unawaited(
        _applyUserLocationSettings(controller.native, widget.showUserLocation),
      );
    }
  }

  Future<void> _hideMapChrome(AppMapController controller) async {
    if (_chromeHidden) return;
    await Future.wait([
      controller.native.logo.updateSettings(
        mapbox.LogoSettings(enabled: false),
      ),
      controller.native.attribution.updateSettings(
        mapbox.AttributionSettings(enabled: false),
      ),
      controller.native.scaleBar.updateSettings(
        mapbox.ScaleBarSettings(enabled: false),
      ),
    ]);
    _chromeHidden = true;
  }

  Future<void> _applyGestureSettings(
    mapbox.MapboxMap controller,
    bool interactive,
  ) {
    return controller.gestures.updateSettings(
      mapbox.GesturesSettings(
        scrollEnabled: interactive,
        rotateEnabled: interactive,
        pitchEnabled: interactive,
        doubleTapToZoomInEnabled: interactive,
        quickZoomEnabled: interactive,
      ),
    );
  }

  Future<void> _applyUserLocationSettings(
    mapbox.MapboxMap controller,
    bool enabled,
  ) {
    return controller.location.updateSettings(
      mapbox.LocationComponentSettings(
        enabled: enabled,
        pulsingEnabled: false,
        showAccuracyRing: false,
      ),
    );
  }

  Future<void> _finishLoading((String, int) identity) async {
    if (!mounted ||
        _mapLoaded ||
        _preparingMap == identity ||
        identity != (widget.styleUri, _mapGeneration)) {
      return;
    }
    _preparingMap = identity;
    try {
      final controller = _mapController;
      if (controller != null) {
        await _hideMapChrome(controller);
      }
      if (!mounted || identity != (widget.styleUri, _mapGeneration)) return;
      setState(() {
        _mapLoaded = true;
        _mapLoadFailed = false;
      });
      widget.onMapLoaded?.call();
    } catch (_) {
      if (mounted && identity == (widget.styleUri, _mapGeneration)) {
        setState(() => _mapLoadFailed = true);
      }
    } finally {
      if (_preparingMap == identity) _preparingMap = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapIdentity = (widget.styleUri, _mapGeneration);
    final map = mapbox.MapWidget(
      key: ValueKey(mapIdentity),
      // ignore: experimental_member_use
      androidHostingMode: mapbox.AndroidPlatformViewHostingMode.TLHC_HC,
      textureView: true,
      styleUri: widget.styleUri,
      viewport: mapbox.CameraViewportState(
        center: mapbox.Point(
          coordinates: mapbox.Position(widget.longitude, widget.latitude),
        ),
        zoom: widget.zoom,
        padding: widget.padding,
      ),
      onMapLoadedListener: (_) => unawaited(_finishLoading(mapIdentity)),
      onMapLoadErrorListener: (_) {
        if (!mounted ||
            _mapLoaded ||
            _mapLoadFailed ||
            mapIdentity != (widget.styleUri, _mapGeneration)) {
          return;
        }
        setState(() => _mapLoadFailed = true);
      },
      onCameraChangeListener: (_) {
        final currentController = _mapController;
        if (currentController != null) {
          widget.onCameraChanged?.call(currentController);
        }
      },
      onMapIdleListener: (_) {
        final currentController = _mapController;
        if (currentController != null) {
          widget.onMapIdle?.call(currentController);
        }
      },
      onMapCreated: (controller) {
        if (!mounted || mapIdentity != (widget.styleUri, _mapGeneration)) {
          return;
        }

        if (!widget.interactive) {
          unawaited(_applyGestureSettings(controller, false));
        }

        final currentController = AppMapController(controller);
        _mapController = currentController;
        if (widget.showUserLocation) {
          unawaited(_applyUserLocationSettings(controller, true));
        }
        if (_mapLoaded && !_chromeHidden) {
          unawaited(_hideMapChrome(currentController));
        }
        widget.onMapCreated?.call(currentController);
      },
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        map,
        if (!_mapLoaded)
          ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(
              child: Semantics(
                liveRegion: true,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_mapLoadFailed) ...[
                        const Text(
                          'The map couldn’t load. Please try again.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => setState(() {
                            _mapController = null;
                            _mapLoadFailed = false;
                            _chromeHidden = false;
                            _preparingMap = null;
                            _mapGeneration++;
                          }),
                          child: const Text('Retry'),
                        ),
                      ] else ...[
                        const CircularProgressIndicator(),
                        const SizedBox(height: 12),
                        const Text('Loading map…'),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
