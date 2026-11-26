import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';

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
  static const List<_PlaceIconOption> _iconOptions = <_PlaceIconOption>[
    _PlaceIconOption(name: 'heart', label: 'Favorite', icon: LucideIcons.heart),
    _PlaceIconOption(name: 'users', label: 'Family', icon: LucideIcons.users),
    _PlaceIconOption(
      name: 'graduation_cap',
      label: 'School',
      icon: LucideIcons.graduation_cap,
    ),
    _PlaceIconOption(name: 'store', label: 'Store', icon: LucideIcons.store),
    _PlaceIconOption(name: 'star', label: 'Starred', icon: LucideIcons.star),
    _PlaceIconOption(
      name: 'map_pin',
      label: 'Pinned place',
      icon: LucideIcons.map_pin,
    ),
    _PlaceIconOption(name: 'house', label: 'Home', icon: LucideIcons.house),
    _PlaceIconOption(
      name: 'briefcase',
      label: 'Work',
      icon: LucideIcons.briefcase,
    ),
  ];

  final TextEditingController _controller = TextEditingController();
  IconData _selectedIcon = LucideIcons.heart;
  bool _isLocationPinned = false;
  bool _isLoadingLocation = true;
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
    final defaultLabel = widget.initialLabel ?? widget.initialPlace?.name;
    if (defaultLabel != null) {
      _controller.text = defaultLabel;
    }
    if (widget.initialIconName != null) {
      _selectedIcon = _iconDataFromName(widget.initialIconName!);
    }
    _controller.addListener(_handleNameChanged);
    if (widget.initialPlace != null) {
      _lat = widget.initialPlace!.latitude;
      _lng = widget.initialPlace!.longitude;
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
      if (position != null) {
        if (!mounted) return;
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
          _isLocationPinned = true;
          _isLoadingLocation = false;
        });
        if (_mapController != null) {
          await MapProvider.moveCamera(_mapController!, _lat, _lng, zoom: 14.0);
          if (!mounted) return;
          await _syncPinnedMarker();
        }
      } else {
        if (!mounted) return;
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
    final label = _controller.text.trim();

    if (label.isEmpty) {
      setState(() => _nameError = 'Enter a name for this place.');
      return;
    }

    if (!_isLocationPinned) {
      _showFailureSnackBar('Pin a location on the map before saving.');
      return;
    }

    final iconName = _iconNameFromData(_selectedIcon);
    final newPlace = SavedPlace(
      label: label,
      iconName: iconName,
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
    for (final option in _iconOptions) {
      if (option.icon == icon) return option.name;
    }
    return 'map_pin';
  }

  IconData _iconDataFromName(String name) {
    for (final option in _iconOptions) {
      if (option.name == name) return option.icon;
    }
    return LucideIcons.map_pin;
  }

  Widget _getMapView(BuildContext context) {
    final customBuilder = widget.mapPreviewBuilder;
    if (customBuilder != null) {
      return customBuilder(context);
    }
    _cachedMapView ??= MapProvider.buildMapView(
      latitude: _lat,
      longitude: _lng,
      zoom: 14.0,
      interactive: true,
      onMapCreated: _onMapCreated,
    );
    return _cachedMapView!;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final animationDuration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 180);
    final canSave = !_isLoadingLocation && _isLocationPinned;

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
                              : _buildLocationUnavailableState(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildFieldLabel(context, 'Location'),
                      const SizedBox(height: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: ExcludeSemantics(
                                child: Icon(
                                  LucideIcons.map_pin,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                widget.initialPlace?.fullAddress ??
                                    (_isLoadingLocation
                                        ? 'Finding your location...'
                                        : _isLocationPinned
                                        ? 'Location pinned'
                                        : 'Location unavailable'),
                                style: textStyles.bodyMedium?.copyWith(
                                  color: _isLocationPinned
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxl),
                      _buildFieldLabel(context, 'Name this place'),
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
                      if (_nameError != null) ...[
                        const SizedBox(height: AppSpacing.xs + 2),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _nameError!,
                            style: textStyles.labelMedium?.copyWith(
                              color: colorScheme.error,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xxl),
                      _buildFieldLabel(context, 'Icon'),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          for (final option in _iconOptions)
                            _buildIconOption(
                              context,
                              option: option,
                              isSelected: _selectedIcon == option.icon,
                              animationDuration: animationDuration,
                            ),
                        ],
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

  Widget _buildFieldLabel(BuildContext context, String label) {
    return Text(
      label.toUpperCase(),
      style: context.textStyles.labelSmall?.copyWith(
        color: context.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.85,
      ),
    );
  }

  Widget _buildIconOption(
    BuildContext context, {
    required _PlaceIconOption option,
    required bool isSelected,
    required Duration animationDuration,
  }) {
    final colorScheme = context.colorScheme;

    return Semantics(
      button: true,
      selected: isSelected,
      label: option.label,
      child: InkWell(
        key: ValueKey<String>('add-place-icon-${option.name}'),
        onTap: () => setState(() => _selectedIcon = option.icon),
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.14);
          }
          return Colors.transparent;
        }),
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: animationDuration,
          curve: Curves.easeOutCubic,
          width: AppSize.minimumTouchTarget,
          height: AppSize.minimumTouchTarget,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerLowest,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            option.icon,
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationUnavailableState(BuildContext context) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  shape: BoxShape.circle,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.map_pin_off,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Location unavailable',
              style: textStyles.titleSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            TextButton.icon(
              onPressed: () {
                setState(() => _isLoadingLocation = true);
                unawaited(_initLocation());
              },
              style:
                  TextButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
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
              icon: const Icon(LucideIcons.refresh_cw, size: 15),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class const _PlaceIconOption({
  required this.name,
  required this.label,
  required this.icon,
}) {
  final String name;
  final String label;
  final IconData icon;
}
