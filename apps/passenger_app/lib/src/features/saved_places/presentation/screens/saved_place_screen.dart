import 'dart:async';

import 'package:core_models/core_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router_modular/go_router_modular.dart';
import 'package:passenger_app/src/features/home/home_routes.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger_app/src/features/saved_places/presentation/bloc/saved_places_cubit.dart';
import 'package:passenger_app/src/features/saved_places/presentation/bloc/saved_places_state.dart';
import 'package:passenger_app/src/features/trip/trip_routes.dart';
import 'package:shared_ui/shared_ui.dart';

class SavedPlaceScreen extends StatefulWidget {
  const SavedPlaceScreen({super.key});

  @override
  State<SavedPlaceScreen> createState() => _SavedPlaceScreenState();
}

class _SavedPlaceScreenState extends State<SavedPlaceScreen> {
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
    final cubit = BlocProvider.of<SavedPlacesCubit>(context);
    final selectedPlace = await context.pushNamed(TripRoutes.mapPin);
    if (selectedPlace == null || selectedPlace is! PlaceModel) return;
    if (!mounted) return;

    if (existing != null) {
      final index = cubit.state.places.indexWhere(
        (p) => p.label.toLowerCase() == label.toLowerCase(),
      );
      if (index != -1) {
        await cubit.removePlace(index);
      }
    }

    final newPlace = SavedPlace(
      label: label,
      iconName: iconName,
      latitude: selectedPlace.latitude,
      longitude: selectedPlace.longitude,
      savedAddress: selectedPlace.name,
    );

    await cubit.addPlace(newPlace);
  }

  Future<void> _openAddCategoryScreen() async {
    final cubit = BlocProvider.of<SavedPlacesCubit>(context);
    final selectedPlace = await context.pushNamed(TripRoutes.mapPin);
    if (selectedPlace == null || selectedPlace is! PlaceModel) return;
    if (!mounted) return;
    await context.pushNamed(
      HomeRoutes.addCategory,
      extra: {
        'onSave': (SavedPlace newPlace) => cubit.addPlace(newPlace),
        'place': selectedPlace,
      },
    );
  }

  void _showPlaceOptions(SavedPlace place, int index) {
    unawaited(
      showModalBottomSheet(
        context: context,
        backgroundColor: AppTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  place.label,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  place.savedAddress ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(
                    LucideIcons.pencil,
                    color: AppTheme.primaryColor,
                  ),
                  title: const Text(
                    'Change Location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
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
                  leading: const Icon(LucideIcons.trash_2, color: Colors.red),
                  title: const Text(
                    'Remove shortcut',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await BlocProvider.of<SavedPlacesCubit>(
                      context,
                    ).removePlace(index);
                  },
                ),
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            LucideIcons.arrow_left,
            color: AppTheme.primaryColor,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Saved places',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w900,
            fontSize: 22,
            letterSpacing: -1.0,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                'Book these in one tap from Home',
                style: TextStyle(
                  fontSize: 15,
                  color: AppTheme.primaryColor.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: BlocBuilder<SavedPlacesCubit, SavedPlacesState>(
                  builder: (context, state) {
                    if (state.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation(
                            AppTheme.primaryColor,
                          ),
                        ),
                      );
                    }

                    // Extract special categories "Home" and "Work"
                    SavedPlace? homePlace;
                    SavedPlace? workPlace;
                    final List<SavedPlace> customPlaces = [];

                    for (final p in state.places) {
                      if (p.label.toLowerCase() == 'home') {
                        homePlace = p;
                      } else if (p.label.toLowerCase() == 'work') {
                        workPlace = p;
                      } else {
                        customPlaces.add(p);
                      }
                    }

                    // Find actual indexes in state.places
                    int indexForPlace(SavedPlace? p) {
                      if (p == null) return -1;
                      return state.places.indexOf(p);
                    }

                    final listItems = <Widget>[
                      _buildPlaceTile(
                        icon: LucideIcons.house,
                        label: 'Home',
                        address:
                            homePlace?.savedAddress ??
                            'Move the map to select a location',
                        onTap: () {
                          if (homePlace == null) {
                            unawaited(_addOrUpdatePlace('Home', 'house'));
                          } else {
                            _showPlaceOptions(
                              homePlace,
                              indexForPlace(homePlace),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildPlaceTile(
                        icon: LucideIcons.briefcase,
                        label: 'Work',
                        address: workPlace?.savedAddress ?? 'Not set',
                        onTap: () {
                          if (workPlace == null) {
                            unawaited(_addOrUpdatePlace('Work', 'briefcase'));
                          } else {
                            _showPlaceOptions(
                              workPlace,
                              indexForPlace(workPlace),
                            );
                          }
                        },
                      ),
                      for (final place in customPlaces) ...[
                        const SizedBox(height: 16),
                        _buildPlaceTile(
                          icon: SavedPlacesCubit.iconFromName(place.iconName),
                          label: place.label,
                          address: place.savedAddress ?? 'Not set',
                          onTap: () => _showPlaceOptions(
                            place,
                            indexForPlace(place),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _openAddCategoryScreen,
                        child: CustomPaint(
                          painter: DashedBorderPainter(
                            color: AppTheme.primaryColor.withValues(alpha: 0.15),
                            borderRadius: 16.0,
                            dashLength: 6.0,
                            gap: 6.0,
                            strokeWidth: 1.5,
                          ),
                          child: Container(
                            height: 64,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.plus,
                                  color: Color(0xFF8A4F35),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Add a new place',
                                  style: TextStyle(
                                    color: Color(0xFF8A4F35),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ];

                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: listItems.length,
                      itemBuilder: (context, index) => listItems[index],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceTile({
    required IconData icon,
    required String label,
    required String address,
    required VoidCallback onTap,
  }) {
    final bool isUnset = address == 'Not set';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: AppTheme.neutralColor.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderSide.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppTheme.secondaryColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF8A4F35), size: 22),
            ),
            const SizedBox(width: 16),
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
                      fontWeight: isUnset ? FontWeight.w600 : FontWeight.w500,
                      color: isUnset
                          ? AppTheme.primaryColor.withValues(alpha: 0.35)
                          : AppTheme.primaryColor.withValues(alpha: 0.65),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevron_right,
              color: AppTheme.primaryColor.withValues(alpha: 0.2),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(borderRadius),
        ),
      );

    final dashPath = Path();
    for (final pathMetric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < pathMetric.length) {
        final length = draw ? dashLength : gap;
        if (draw) {
          dashPath.addPath(
            pathMetric.extractPath(distance, distance + length),
            Offset.zero,
          );
        }
        distance += length;
        draw = !draw;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
