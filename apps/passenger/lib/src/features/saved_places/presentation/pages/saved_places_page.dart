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
      await cubit.invalidateAndReload();
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
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: false,
        backgroundColor: colorScheme.surfaceContainerLowest,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        builder: (sheetContext) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppLayout.pagePadding,
                AppSpacing.md,
                AppLayout.pagePadding,
                AppSpacing.md,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    place.label,
                    textAlign: TextAlign.center,
                    style: textStyles.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if ((place.savedAddress ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      place.savedAddress!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: textStyles.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _buildHairline(sheetContext),
                  _buildSheetAction(
                    sheetContext,
                    icon: place.isDefault
                        ? LucideIcons.circle_check
                        : LucideIcons.circle,
                    title: place.isDefault
                        ? 'Default Home quick action'
                        : 'Set as Home quick action',
                    subtitle: place.isDefault
                        ? 'Shown as the only saved place on Home'
                        : 'Show this place as the only saved place on Home',
                    onTap: place.isDefault
                        ? () => Navigator.of(sheetContext).pop()
                        : () {
                            Navigator.of(sheetContext).pop();
                            unawaited(_setDefaultPlace(index));
                          },
                  ),
                  _buildHairline(sheetContext, indent: 36),
                  _buildSheetAction(
                    sheetContext,
                    icon: LucideIcons.pencil,
                    title: 'Change location',
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
                  _buildHairline(sheetContext, indent: 36),
                  _buildSheetAction(
                    sheetContext,
                    icon: LucideIcons.trash_2,
                    title: 'Remove shortcut',
                    isDestructive: true,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      unawaited(
                        BlocProvider.of<SavedPlacesCubit>(context)
                            .removePlace(index),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSheetAction(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;
    final foregroundColor = isDestructive
        ? colorScheme.error
        : colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      enableFeedback: false,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return foregroundColor.withValues(alpha: 0.12);
        }
        return Colors.transparent;
      }),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppSize.minimumTouchTarget + 8,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textStyles.titleSmall?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: foregroundColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: textStyles.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
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
    if (AppNetworkStatusScope.isUnavailableOf(context)) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
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
        if (state.errorMessage != null &&
            state.errorSource == SavedPlacesErrorSource.load) ...[
          AppErrorBanner(
            message: state.errorMessage!,
            onRetry: () => unawaited(
              BlocProvider.of<SavedPlacesCubit>(context).loadPlaces(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _buildSectionHeading(
          title: 'Everyday shortcuts',
          subtitle: 'The places you reach for most.',
        ),
        const SizedBox(height: AppSpacing.xs),
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
        _buildHairline(context, indent: 52),
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
          const SizedBox(height: AppSpacing.xxl),
          _buildSectionHeading(
            title: 'Other places',
            subtitle: 'Keep favorite destinations close.',
          ),
          const SizedBox(height: AppSpacing.xs),
          for (var index = 0; index < customPlaces.length; index++) ...[
            _buildPlaceTile(
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
              _buildHairline(context, indent: 52),
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

  Widget _buildHairline(BuildContext context, {double indent = 0}) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      color: context.colorScheme.outlineVariant.withValues(alpha: 0.65),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
  }) {
    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.textStyles.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultBadge() {
    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Text(
        'Default',
        style: context.textStyles.labelSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
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
    final colorScheme = context.colorScheme;
    final textStyles = context.textStyles;

    return Semantics(
      button: true,
      label: isDefault ? '$label, Default, $address' : '$label, $address',
      child: InkWell(
        key: ValueKey<String>(_placeKey(label)),
        onTap: onTap,
        enableFeedback: false,
        splashFactory: NoSplash.splashFactory,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.focused)) {
            return colorScheme.primary.withValues(alpha: 0.12);
          }
          return Colors.transparent;
        }),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: AppSize.minimumTouchTarget + 18,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isConfigured
                          ? colorScheme.primaryContainer
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isConfigured
                            ? colorScheme.primary.withValues(alpha: 0.12)
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      icon,
                      color: isConfigured
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                      size: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            label,
                            style: textStyles.titleSmall?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          if (isDefault) _buildDefaultBadge(),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textStyles.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                ExcludeSemantics(
                  child: Icon(
                    isConfigured ? LucideIcons.chevron_right : LucideIcons.plus,
                    color: colorScheme.onSurfaceVariant,
                    size: 17,
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
