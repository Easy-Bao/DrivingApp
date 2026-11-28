import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/booking/booking_routes.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places_cubit.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places_state.dart';
import 'package:passenger/src/features/saved_places/presentation/widgets/saved_place_auth.dart';
import 'package:passenger/src/features/saved_places/presentation/widgets/saved_place_icon.dart';
import 'package:passenger/src/features/saved_places/presentation/widgets/saved_places_widgets.dart';
import 'package:passenger/src/features/saved_places/saved_places_routes.dart';
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
        unawaited(
          BlocProvider.of<SavedPlacesCubit>(context).invalidateAndReload(),
        );
      }
    });
  }

  Future<void> _refreshPlaces() {
    return BlocProvider.of<SavedPlacesCubit>(context).invalidateAndReload();
  }

  Future<void> _addOrUpdatePlace(
    String label,
    String iconName, {
    SavedPlace? existing,
  }) async {
    if (_isPlaceFlowOpen) return;
    _isPlaceFlowOpen = true;
    try {
      if (!await ensureSavedPlaceAuthentication(context) || !mounted) return;
      final cubit = BlocProvider.of<SavedPlacesCubit>(context);
      final selectedPlace = await context.pushNamed<Place>(
        BookingRoutes.mapPin,
        queryParameters: {'savedPlace': '1'},
      );
      if (selectedPlace == null || !mounted) return;

      final configuredPlace = await context.pushNamed<SavedPlace>(
        SavedPlacesRoutes.addCategory,
        extra: {
          'place': selectedPlace,
          'initialLabel': label,
          'initialIconName': iconName,
          'isEditing': existing != null,
        },
      );
      if (configuredPlace == null || !mounted) return;

      final existingIndex = existing == null
          ? -1
          : cubit.state.places.indexWhere(
              (place) =>
                  place.label.toLowerCase() == existing.label.toLowerCase(),
            );
      final isUpdating = existingIndex != -1;
      if (!isUpdating) {
        await cubit.addPlace(configuredPlace);
      } else {
        await cubit.replacePlace(existingIndex, configuredPlace);
      }
      final error = cubit.state.errorMessage;
      if (error != null &&
          cubit.state.errorSource == SavedPlacesErrorSource.persistence) {
        if (mounted) {
          _showFailureSnackBar(error);
        }
        return;
      }
      await cubit.invalidateAndReload();
      if (mounted) {
        AppSnackBar.show(
          context,
          isUpdating
              ? '${configuredPlace.label} updated.'
              : '${configuredPlace.label} saved.',
        );
      }
    } finally {
      _isPlaceFlowOpen = false;
    }
  }

  Future<void> _openAddCategoryPage() async {
    if (_isPlaceFlowOpen) return;
    _isPlaceFlowOpen = true;
    try {
      if (!await ensureSavedPlaceAuthentication(context) || !mounted) return;
      final cubit = BlocProvider.of<SavedPlacesCubit>(context);
      final selectedPlace = await context.pushNamed<Place>(
        BookingRoutes.mapPin,
        queryParameters: {'savedPlace': '1'},
      );
      if (selectedPlace == null || !mounted) return;
      final newPlace = await context.pushNamed<SavedPlace>(
        SavedPlacesRoutes.addCategory,
        extra: {'place': selectedPlace},
      );
      if (newPlace != null && mounted) {
        await cubit.addPlace(newPlace);
        final error = cubit.state.errorMessage;
        if (!mounted) return;
        if (error != null &&
            cubit.state.errorSource == SavedPlacesErrorSource.persistence) {
          _showFailureSnackBar(error);
        } else {
          AppSnackBar.show(context, '${newPlace.label} saved.');
        }
      }
    } finally {
      _isPlaceFlowOpen = false;
    }
  }

  void _showPlaceOptions(SavedPlace place, int index) {
    unawaited(
      showSavedPlaceOptionsSheet(
        context,
        place: place,
        onSetDefault: () => unawaited(_setDefaultPlace(index)),
        onChangeLocation: () => unawaited(
          _addOrUpdatePlace(place.label, place.iconName, existing: place),
        ),
        onRemove: () => unawaited(_removePlace(place, index)),
      ),
    );
  }

  Future<void> _removePlace(SavedPlace place, int index) async {
    if (!mounted) return;
    final cubit = BlocProvider.of<SavedPlacesCubit>(context);
    await cubit.removePlace(index);
    if (!mounted) return;

    final error = cubit.state.errorMessage;
    if (error != null &&
        cubit.state.errorSource == SavedPlacesErrorSource.persistence) {
      _showFailureSnackBar(error);
      return;
    }

    AppSnackBar.show(
      context,
      '${place.label} removed.',
      tone: AppSnackBarTone.info,
      actionLabel: 'Undo',
      onAction: () => unawaited(_restorePlace(index, place)),
    );
  }

  Future<void> _restorePlace(int index, SavedPlace place) async {
    if (!mounted) return;
    final cubit = BlocProvider.of<SavedPlacesCubit>(context);
    await cubit.restorePlace(index, place);
    if (!mounted) return;

    final error = cubit.state.errorMessage;
    if (error != null &&
        cubit.state.errorSource == SavedPlacesErrorSource.persistence) {
      _showFailureSnackBar(error);
    }
  }

  Future<void> _setDefaultPlace(int index) async {
    if (!mounted) return;
    final cubit = BlocProvider.of<SavedPlacesCubit>(context);
    if (index < 0 || index >= cubit.state.places.length) return;
    final placeLabel = cubit.state.places[index].label;
    await cubit.setDefaultPlace(index);
    if (!mounted) return;

    final error = cubit.state.errorMessage;
    if (error != null &&
        cubit.state.errorSource == SavedPlacesErrorSource.persistence) {
      _showFailureSnackBar(error);
      return;
    }
    AppSnackBar.show(context, '$placeLabel set as Home quick action.');
  }

  void _showFailureSnackBar(String message) {
    if (AppNetworkStatusScope.isUnavailableOf(context)) return;
    AppSnackBar.show(context, message, tone: AppSnackBarTone.error);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.canvasColor,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
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
          icon: Icon(
            LucideIcons.arrow_left,
            color: colorScheme.onSurface,
            size: 20,
          ),
        ),
        title: Text(
          'Saved places',
          style: context.textStyles.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 360
                ? AppLayout.pagePadding
                : AppLayout.pagePaddingWide;
            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: RefreshIndicator(
                  color: colorScheme.onSurface,
                  backgroundColor: colorScheme.surfaceContainerLowest,
                  onRefresh: _refreshPlaces,
                  child: BlocBuilder<SavedPlacesCubit, SavedPlacesState>(
                    builder: (context, state) {
                      final content = _buildSavedPlacesList(
                        state,
                        horizontalPadding: horizontalPadding,
                      );
                      if (state.isLoading && state.places.isNotEmpty) {
                        return Skeletonizer.zone(
                          child: IgnorePointer(child: content),
                        );
                      }
                      return content;
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSavedPlacesList(
    SavedPlacesState state, {
    required double horizontalPadding,
  }) {
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
    final colorScheme = context.colorScheme;

    return ListView(
      key: const ValueKey<String>('saved-places-scroll'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        AppSpacing.md,
        horizontalPadding,
        AppSpacing.xxxl,
      ),
      children: [
        if (state.errorMessage case final errorMessage?
            when state.errorSource == SavedPlacesErrorSource.load) ...[
          AppErrorBanner(
            message: errorMessage,
            onRetry: () => unawaited(
              BlocProvider.of<SavedPlacesCubit>(context).loadPlaces(),
            ),
            onDismiss: () =>
                BlocProvider.of<SavedPlacesCubit>(context).dismissError(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        const SavedPlacesSectionHeading(
          title: 'Everyday shortcuts',
          subtitle: 'The places you reach for most.',
        ),
        const SizedBox(height: AppSpacing.xs),
        SavedPlaceTile(
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
        const SavedPlacesHairline(indent: 52),
        SavedPlaceTile(
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
          const SizedBox(height: AppSpacing.xxl),
          const SavedPlacesSectionHeading(
            title: 'Other places',
            subtitle: 'Keep favorite destinations close.',
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var index = 0; index < customPlaces.length; index++) ...[
            SavedPlaceTile(
              icon: savedPlaceIconFromName(customPlaces[index].iconName),
              label: customPlaces[index].label,
              address:
                  customPlaces[index].savedAddress ?? 'Location unavailable',
              isConfigured: customPlaces[index].hasLocation,
              isDefault: customPlaces[index].isDefault,
              onTap: () => _showPlaceOptions(
                customPlaces[index],
                indexForPlace(customPlaces[index]),
              ),
            ),
            if (index != customPlaces.length - 1)
              const SavedPlacesHairline(indent: 52),
          ],
        ],
        const SizedBox(height: AppSpacing.xxl),
        SizedBox(
          width: double.infinity,
          height: AppSize.controlHeight,
          child: OutlinedButton.icon(
            key: const ValueKey<String>('saved-places-add-button'),
            onPressed: _openAddCategoryPage,
            icon: const Icon(LucideIcons.plus, size: 17),
            label: const Text('Add a new place'),
            style:
                OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                  backgroundColor: Colors.transparent,
                  side: BorderSide(color: colorScheme.outlineVariant),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
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
          ),
        ),
      ],
    );
  }
}
