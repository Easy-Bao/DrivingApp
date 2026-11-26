import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/presentation/widgets/add_saved_place_widgets.dart';

class const AddCategoryPage({
  super.key,
  this.initialPlace,
  this.initialLabel,
  this.initialIconName,
  this.mapPreviewBuilder,
}) extends StatefulWidget {
  final Place? initialPlace;
  final String? initialLabel;
  final String? initialIconName;
  final WidgetBuilder? mapPreviewBuilder;

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final TextEditingController _controller = TextEditingController();
  IconData _selectedIcon = LucideIcons.heart;
  bool _isLocationPinned = false;
  bool _isLoadingLocation = true;
  bool _isSaving = false;
  double _lat = 0.0;
  double _lng = 0.0;
  String? _nameError;
  AppMapController? _mapController;
  MapPointAnnotationManager? _pinAnnotationManager;
  int _pinRequestId = 0;
  Widget? _cachedMapView;

  @override
  void initState() {
    super.initState();
    final initialPlace = widget.initialPlace;
    final defaultLabel = widget.initialLabel ?? initialPlace?.name;
    if (defaultLabel != null) {
      _controller.text = defaultLabel;
    }
    if (widget.initialIconName case final iconName?) {
      _selectedIcon = _iconDataFromName(iconName);
    }
    _controller.addListener(_handleNameChanged);
    if (initialPlace != null) {
      _lat = initialPlace.latitude;
      _lng = initialPlace.longitude;
      _isLocationPinned = true;
      _isLoadingLocation = false;
    } else {
      unawaited(_initLocation());
    }
  }

  @override
  void dispose() {
    _pinRequestId++;
    unawaited(MapProvider.clearAnnotations(_pinAnnotationManager));
    _controller.removeListener(_handleNameChanged);
    _controller.dispose();
    super.dispose();
  }

  void _handleNameChanged() {
    if (_nameError != null && _controller.text.trim().isNotEmpty && mounted) {
      setState(() => _nameError = null);
    }
  }

  Future<void> _initLocation() async {
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (position != null) {
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
          _isLocationPinned = true;
          _isLoadingLocation = false;
        });
        final controller = _mapController;
        if (controller != null) {
          await MapProvider.moveCamera(controller, _lat, _lng, zoom: 14.0);
          if (!mounted) return;
          await _syncPinnedMarker();
        }
      } else {
        setState(() {
          _isLocationPinned = false;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLocationPinned = false;
        _isLoadingLocation = false;
      });
    }
  }

  void _onMapCreated(AppMapController controller) {
    _mapController = controller;
    if (_isLocationPinned) {
      unawaited(_syncPinnedMarker());
    }
  }

  Future<void> _syncPinnedMarker() async {
    final controller = _mapController;
    if (!mounted || controller == null || !_isLocationPinned) return;

    final requestId = ++_pinRequestId;
    final color = context.colorScheme.onSurface;
    final existingManager = _pinAnnotationManager;
    if (existingManager != null) {
      await MapProvider.replaceMarker(
        existingManager,
        _lat,
        _lng,
        isOrigin: false,
        color: color,
      );
      return;
    }

    final manager = await MapProvider.addMarker(
      controller,
      _lat,
      _lng,
      isOrigin: false,
      color: color,
    );
    if (!mounted || requestId != _pinRequestId) {
      await MapProvider.clearAnnotations(manager);
      return;
    }
    _pinAnnotationManager = manager;
  }

  void _handleSave() {
    if (_isSaving) return;
    final label = _controller.text.trim();

    if (label.isEmpty) {
      setState(() => _nameError = 'Enter a name for this place.');
      return;
    }

    if (!_isLocationPinned) {
      _showFailureSnackBar('Pin a location on the map before saving.');
      return;
    }

    _isSaving = true;
    final newPlace = SavedPlace(
      label: label,
      iconName: _iconNameFromData(_selectedIcon),
      latitude: _lat,
      longitude: _lng,
      savedAddress: widget.initialPlace?.fullAddress ?? label,
    );

    context.pop(newPlace);
  }

  void _showFailureSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _iconNameFromData(IconData icon) {
    for (final option in savedPlaceIconOptions) {
      if (option.icon == icon) return option.name;
    }
    return 'map_pin';
  }

  IconData _iconDataFromName(String name) {
    for (final option in savedPlaceIconOptions) {
      if (option.name == name) return option.icon;
    }
    return LucideIcons.map_pin;
  }

  Widget _getMapView(BuildContext context) {
    final customBuilder = widget.mapPreviewBuilder;
    if (customBuilder != null) {
      return customBuilder(context);
    }
    return _cachedMapView ??= MapProvider.buildMapView(
      latitude: _lat,
      longitude: _lng,
      zoom: 14.0,
      interactive: true,
      onMapCreated: _onMapCreated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final canSave = !_isLoadingLocation && _isLocationPinned;
    final addressLabel =
        widget.initialPlace?.fullAddress ??
        (_isLoadingLocation
            ? 'Finding your location...'
            : _isLocationPinned
            ? 'Location pinned'
            : 'Location unavailable');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.canvasColor,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          style:
              IconButton.styleFrom(
                enableFeedback: false,
                splashFactory: NoSplash.splashFactory,
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.focused)) {
                    return colorScheme.primary.withValues(alpha: 0.12);
                  }
                  return Colors.transparent;
                }),
              ),
          icon: Icon(LucideIcons.x, color: colorScheme.onSurface, size: 20),
        ),
        title: Text(
          'Add place',
          style: textStyles.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: TextButton(
              key: const ValueKey<String>('add-place-save'),
              onPressed: canSave ? _handleSave : null,
              style:
                  TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    disabledForegroundColor: colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.42),
                    enableFeedback: false,
                    splashFactory: NoSplash.splashFactory,
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.focused)) {
                        return colorScheme.primary.withValues(alpha: 0.12);
                      }
                      return Colors.transparent;
                    }),
                  ),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360
                ? AppLayout.pagePadding
                : AppLayout.pagePaddingWide;
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                AppSpacing.md,
                horizontalPadding,
                AppSpacing.xxxl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        child: Container(
                          height: 220,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                            ),
                          ),
                          child: _isLoadingLocation
                              ? Center(
                                  child: SizedBox.square(
                                    dimension: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                )
                              : _isLocationPinned
                              ? _getMapView(context)
                              : SavedPlaceLocationUnavailableView(
                                  onRetry: () {
                                    setState(() => _isLoadingLocation = true);
                                    unawaited(_initLocation());
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      const SavedPlaceFieldLabel('Location'),
                      const SizedBox(height: AppSpacing.sm),
                      SavedPlaceLocationCard(
                        addressLabel: addressLabel,
                        isLocationPinned: _isLocationPinned,
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      const SavedPlaceFieldLabel('Name this place'),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        key: const ValueKey<String>('add-place-name-field'),
                        controller: _controller,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        style: textStyles.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: "e.g. Ate's house",
                          hintStyle: textStyles.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerLowest,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: 15,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            borderSide: BorderSide(
                              color: _nameError != null
                                  ? colorScheme.error
                                  : colorScheme.outlineVariant,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            borderSide: BorderSide(
                              color: _nameError != null
                                  ? colorScheme.error
                                  : colorScheme.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      if (_nameError case final nameError?) ...[
                        const SizedBox(height: AppSpacing.xs + 2),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            nameError,
                            style: textStyles.labelMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      const SavedPlaceFieldLabel('Icon'),
                      const SizedBox(height: AppSpacing.md),
                      SavedPlaceIconPicker(
                        selectedIcon: _selectedIcon,
                        animationDuration: animationDuration,
                        onSelected: (icon) =>
                            setState(() => _selectedIcon = icon),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
