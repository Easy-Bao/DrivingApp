import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/core/theme/app_theme.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/saved_places/bloc/saved_places/saved_places_cubit.dart';
import 'package:passenger_app/src/features/saved_places/bloc/saved_places/saved_places_state.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/saved_places/view/saved_place_icon.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:passenger_app/src/shared/widgets/app_back_button_widget.dart';
import 'package:shared_core/shared_core.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SavedPlacePage extends StatefulWidget {
  const SavedPlacePage({super.key});

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
      final selectedPlace = await context.pushNamed<PlaceModel>(
        TripRoutes.mapPin,
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
    } finally {
      _isPlaceFlowOpen = false;
    }
  }

  Future<void> _openAddCategoryPage() async {
    if (_isPlaceFlowOpen) return;
    _isPlaceFlowOpen = true;
    try {
      final cubit = BlocProvider.of<SavedPlacesCubit>(context);
      final selectedPlace = await context.pushNamed<PlaceModel>(
        TripRoutes.mapPin,
      );
      if (selectedPlace == null || !mounted) return;
      final newPlace = await context.pushNamed<SavedPlace>(
        HomeRoutes.addCategory,
        extra: {'place': selectedPlace},
      );
      if (newPlace != null && mounted) {
        await cubit.addPlace(newPlace);
      }
    } finally {
      _isPlaceFlowOpen = false;
    }
  }

  void _showPlaceOptions(SavedPlace place, int index) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: AppTheme.borderSide,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  place.label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
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
                        color: AppTheme.primaryColor.withValues(alpha: 0.55),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.borderSide),
                ListTile(
                  leading: const Icon(
                    LucideIcons.pencil,
                    color: AppTheme.primaryColor,
                  ),
                  title: const Text(
                    'Change location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
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
                  leading: const Icon(
                    LucideIcons.trash_2,
                    color: AppTheme.cancel,
                  ),
                  title: const Text(
                    'Remove shortcut',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.cancel,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    await BlocProvider.of<SavedPlacesCubit>(
                      context,
                    ).removePlace(index);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Center(
          child: AppBackButtonWidget.plain(onPressed: () => context.pop()),
        ),
        title: const Text(
          'Saved places',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Quick destinations ready from Home.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.primaryColor.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
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
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (state.errorMessage != null) ...[
          _buildLoadIssue(state.errorMessage!),
          const SizedBox(height: 16),
        ],
        _buildSectionLabel('Essentials'),
        const SizedBox(height: 10),
        _buildPlaceTile(
          icon: LucideIcons.house,
          label: 'Home',
          address: homePlace?.savedAddress ?? 'Choose a location',
          isConfigured: homePlace != null,
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
          _buildSectionLabel('Other Places'),
          const SizedBox(height: 10),
          for (final place in customPlaces) ...[
            _buildPlaceTile(
              icon: savedPlaceIconFromName(place.iconName),
              label: place.label,
              address: place.savedAddress ?? 'Location unavailable',
              isConfigured: place.hasLocation,
              onTap: () => _showPlaceOptions(place, indexForPlace(place)),
            ),
            const SizedBox(height: 12),
          ],
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: _openAddCategoryPage,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add a new place'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.borderSide),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadIssue(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cancel.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cancel.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.circle_alert,
            color: AppTheme.cancel,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.cancel,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => unawaited(
              BlocProvider.of<SavedPlacesCubit>(context).loadPlaces(),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: AppTheme.primaryColor.withValues(alpha: 0.42),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.9,
      ),
    );
  }

  Widget _buildPlaceTile({
    required IconData icon,
    required String label,
    required String address,
    required bool isConfigured,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isConfigured
              ? AppTheme.surface
              : AppTheme.neutralColor.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isConfigured
                ? AppTheme.borderSide
                : AppTheme.borderSide.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isConfigured
                    ? AppTheme.secondaryColor
                    : AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isConfigured
                          ? FontWeight.w500
                          : FontWeight.w600,
                      color: isConfigured
                          ? AppTheme.primaryColor.withValues(alpha: 0.58)
                          : AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isConfigured ? LucideIcons.pencil : LucideIcons.plus,
              color: AppTheme.tertiaryColor,
              size: isConfigured ? 16 : 18,
            ),
          ],
        ),
      ),
    );
  }
}
