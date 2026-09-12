import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/home/home_routes.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places/saved_places_cubit.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places/saved_places_state.dart';
import 'package:passenger/src/features/saved_places/presentation/saved_place_icon.dart';
import 'package:skeletonizer/skeletonizer.dart';

class const SavedPlacePage({super.key}) extends StatefulWidget {
  @override
  State<SavedPlacePage> createState() => _SavedPlacePageState();
}

class _SavedPlacePageState extends State<SavedPlacePage> {
  bool _isPlaceFlowOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(BlocProvider.of<SavedPlacesCubit>(context).loadPlaces());
      }
    });
  }

  Future<void> _addOrUpdatePlace(
    String label,
    String iconName, {
    SavedPlace? existing,
  }) async {
    if (_isPlaceFlowOpen) return;
    _isPlaceFlowOpen = true;
    try {
      final cubit = BlocProvider.of<SavedPlacesCubit>(context);
      final selectedPlace = await context.pushNamed<Place>(
        BookingRoutes.mapPin,
      );
      if (selectedPlace == null || !mounted) return;

      final configuredPlace = await context.pushNamed<SavedPlace>(
        HomeRoutes.addCategory,
        extra: {
          'place': selectedPlace,
          'initialLabel': label,
          'initialIconName': iconName,
        },
      );
      if (configuredPlace == null || !mounted) return;

      final existingIndex = existing == null
          ? -1
          : cubit.state.places.indexWhere(
              (place) =>
                  place.label.toLowerCase() == existing.label.toLowerCase(),
            );
      if (existingIndex == -1) {
        await cubit.addPlace(configuredPlace);
      } else {
        await cubit.replacePlace(existingIndex, configuredPlace);
      }
      final error = cubit.state.errorMessage;
      if (mounted &&
          error != null &&
          cubit.state.errorSource == SavedPlacesErrorSource.persistence) {
        _showFailureSnackBar(error);
      }
    } finally {
      _isPlaceFlowOpen = false;
    }
  }

  Future<void> _openAddCategoryPage() async {
    if (_isPlaceFlowOpen) return;
    _isPlaceFlowOpen = true;
    try {
      final cubit = BlocProvider.of<SavedPlacesCubit>(context);
      final selectedPlace = await context.pushNamed<Place>(
        BookingRoutes.mapPin,
      );
      if (selectedPlace == null || !mounted) return;
      final newPlace = await context.pushNamed<SavedPlace>(
        HomeRoutes.addCategory,
        extra: {'place': selectedPlace},
      );
      if (newPlace != null && mounted) {
        await cubit.addPlace(newPlace);
        final error = cubit.state.errorMessage;
        if (mounted &&
            error != null &&
            cubit.state.errorSource == SavedPlacesErrorSource.persistence) {
          _showFailureSnackBar(error);
        }
      }
    } finally {
      _isPlaceFlowOpen = false;
    }
  }

  void _showPlaceOptions(SavedPlace place, int index) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: context.colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(EasyRideDesignTokens.cardRadius),
          ),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: context.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  place.label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.colorScheme.onSurface,
                  ),
                ),
                if ((place.savedAddress ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      place.savedAddress!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Divider(height: 1, color: context.colorScheme.outlineVariant),
                ListTile(
                  leading: Icon(
                    place.isDefault
                        ? LucideIcons.circle_check
                        : LucideIcons.circle,
                    color: place.isDefault
                        ? context.colorScheme.onSurface
                        : context.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    place.isDefault
                        ? 'Default Home quick action'
                        : 'Set as Home quick action',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    place.isDefault
                        ? 'Shown as the only saved place on Home'
                        : 'Show this place as the only saved place on Home',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: place.isDefault
                      ? () => Navigator.of(sheetContext).pop()
                      : () {
                          Navigator.of(sheetContext).pop();
                          unawaited(_setDefaultPlace(index));
                        },
                ),
                ListTile(
                  leading: Icon(
                    LucideIcons.pencil,
                    color: context.colorScheme.onSurface,
                  ),
                  title: Text(
                    'Change location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    unawaited(
                      _addOrUpdatePlace(
                        place.label,
                        place.iconName,
                        existing: place,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    LucideIcons.trash_2,
                    color: context.colorScheme.error,
                  ),
                  title: Text(
                    'Remove shortcut',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.error,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await BlocProvider.of<SavedPlacesCubit>(context)
                        .removePlace(index);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _setDefaultPlace(int index) async {
    final cubit = BlocProvider.of<SavedPlacesCubit>(context);
    await cubit.setDefaultPlace(index);
    if (!mounted) return;

    final error = cubit.state.errorMessage;
    if (error != null &&
        cubit.state.errorSource == SavedPlacesErrorSource.persistence) {
      _showFailureSnackBar(error);
    }
  }

  void _showFailureSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360
                ? EasyRideDesignTokens.pageHorizontalPadding
                : EasyRideDesignTokens.pageHorizontalPaddingWide;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPageHeader(),
                      Expanded(
                        child: BlocBuilder<SavedPlacesCubit, SavedPlacesState>(
                          builder: (context, state) {
                            final content = _buildSavedPlacesList(state);
                            if (state.isLoading && state.places.isNotEmpty) {
                              return Skeletonizer.zone(
                                child: IgnorePointer(child: content),
                              );
                            }
                            return content;
                          },
                        ),
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

  Widget _buildPageHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text('Saved places', style: context.textStyles.headlineSmall),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => context.pop(),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  shape: const CircleBorder(),
                ),
                icon: Icon(
                  LucideIcons.arrow_left,
                  color: context.colorScheme.onSurface,
                  size: 21,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedPlacesList(SavedPlacesState state) {
    SavedPlace? homePlace;
    SavedPlace? workPlace;
    final customPlaces = <SavedPlace>[];

    for (final place in state.places) {
      if (place.label.toLowerCase() == 'home') {
        homePlace = place;
      } else if (place.label.toLowerCase() == 'work') {
        workPlace = place;
      } else {
        customPlaces.add(place);
      }
    }

    int indexForPlace(SavedPlace place) => state.places.indexOf(place);

    return ListView(
      key: const ValueKey<String>('saved-places-scroll'),
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (state.errorMessage != null &&
            state.errorSource == SavedPlacesErrorSource.load) ...[
          AppErrorBanner(
            message: state.errorMessage!,
            onRetry: () => unawaited(
              BlocProvider.of<SavedPlacesCubit>(context).loadPlaces(),
            ),
          ),
          const SizedBox(height: 14),
        ],
        _buildSectionHeading(
          title: 'Everyday shortcuts',
          subtitle: 'The places you reach for most.',
        ),
        const SizedBox(height: 10),
        _buildPlaceTile(
          icon: LucideIcons.house,
          label: 'Home',
          address: homePlace?.savedAddress ?? 'Choose a location',
          isConfigured: homePlace != null,
          isDefault: homePlace?.isDefault ?? false,
          onTap: () {
            if (homePlace == null) {
              unawaited(_addOrUpdatePlace('Home', 'house'));
              return;
            }
            _showPlaceOptions(homePlace, indexForPlace(homePlace));
          },
        ),
        const SizedBox(height: 12),
        _buildPlaceTile(
          icon: LucideIcons.briefcase,
          label: 'Work',
          address: workPlace?.savedAddress ?? 'Choose a location',
          isConfigured: workPlace != null,
          isDefault: workPlace?.isDefault ?? false,
          onTap: () {
            if (workPlace == null) {
              unawaited(_addOrUpdatePlace('Work', 'briefcase'));
              return;
            }
            _showPlaceOptions(workPlace, indexForPlace(workPlace));
          },
        ),
        if (customPlaces.isNotEmpty) ...[
          const SizedBox(height: 24),
          _buildSectionHeading(
            title: 'Other places',
            subtitle: 'Keep favorite destinations close.',
          ),
          const SizedBox(height: 10),
          for (final place in customPlaces) ...[
            _buildPlaceTile(
              icon: savedPlaceIconFromName(place.iconName),
              label: place.label,
              address: place.savedAddress ?? 'Location unavailable',
              isConfigured: place.hasLocation,
              isDefault: place.isDefault,
              onTap: () => _showPlaceOptions(place, indexForPlace(place)),
            ),
            const SizedBox(height: 12),
          ],
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton.icon(
            onPressed: _openAddCategoryPage,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add a new place'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colorScheme.onSurface,
              side: BorderSide(color: context.colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  EasyRideDesignTokens.sheetRadius,
                ),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.textStyles.titleMedium),
        const SizedBox(height: 2),
        Text(subtitle, style: context.textStyles.bodySmall),
      ],
    );
  }

  Widget _buildDefaultBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: context.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(EasyRideDesignTokens.smallRadius),
      ),
      child: Text(
        'Default',
        style: TextStyle(
          color: context.colorScheme.onSecondaryContainer,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _placeKey(String label) => 'saved-place-$label';

  Widget _buildPlaceTile({
    required IconData icon,
    required String label,
    required String address,
    required bool isConfigured,
    required bool isDefault,
    required VoidCallback onTap,
  }) {
    final backgroundColor = isDefault
        ? context.colorScheme.secondaryContainer.withValues(alpha: 0.28)
        : isConfigured
        ? context.colorScheme.surface
        : context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    return Semantics(
      button: true,
      label: '$label, $address',
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(EasyRideDesignTokens.cardRadius),
        child: InkWell(
          key: ValueKey<String>(_placeKey(label)),
          onTap: onTap,
          borderRadius: BorderRadius.circular(EasyRideDesignTokens.cardRadius),
          child: Container(
            padding: const EdgeInsets.all(EasyRideDesignTokens.cardPadding),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                EasyRideDesignTokens.cardRadius,
              ),
              border: Border.all(
                color: isDefault
                    ? context.colorScheme.primary.withValues(alpha: 0.28)
                    : context.colorScheme.outlineVariant,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDefault
                        ? context.colorScheme.secondaryContainer
                        : isConfigured
                        ? context.colorScheme.primaryContainer
                        : context.colorScheme.surface,
                    borderRadius: BorderRadius.circular(
                      EasyRideDesignTokens.controlRadius,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: context.colorScheme.onSurface,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: context.textStyles.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textStyles.bodySmall?.copyWith(
                          fontWeight: isConfigured
                              ? FontWeight.w500
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isDefault) _buildDefaultBadge(),
                    if (isDefault) const SizedBox(height: 5),
                    Icon(
                      isConfigured
                          ? LucideIcons.chevron_right
                          : LucideIcons.plus,
                      color: context.colorScheme.onSurfaceVariant,
                      size: isConfigured ? 18 : 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
