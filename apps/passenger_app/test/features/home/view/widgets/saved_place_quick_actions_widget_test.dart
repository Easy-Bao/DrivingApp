import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/home/view/widgets/saved_place_quick_actions_widget.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  testWidgets('renders every saved place with only the default active', (
    WidgetTester tester,
  ) async {
    SavedPlace? tappedPlace;

    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: Scaffold(
          body: SavedPlaceQuickActionsWidget(
            places: const [
              SavedPlace(
                label: 'Home',
                iconName: 'house',
                isDefault: true,
                latitude: 14.6,
                longitude: 120.98,
              ),
              SavedPlace(
                label: 'Near Bathroom',
                iconName: 'map_pin',
                latitude: 14.61,
                longitude: 120.99,
              ),
              SavedPlace(
                label: 'Work',
                iconName: 'briefcase',
                latitude: 14.62,
                longitude: 121.0,
              ),
            ],
            onPlaceTap: (place) => tappedPlace = place,
            onAddPlace: () {},
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Near Bathroom'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Add place'), findsOneWidget);
    expect(find.byType(AnimatedContainer), findsNWidgets(3));

    final chips = find.byType(AnimatedContainer);
    final firstDecoration =
        tester.widget<AnimatedContainer>(chips.at(0)).decoration
            as BoxDecoration;
    final secondDecoration =
        tester.widget<AnimatedContainer>(chips.at(1)).decoration
            as BoxDecoration;
    expect(firstDecoration.color, EasyRideTheme.light.colorScheme.primary);
    expect(secondDecoration.color, EasyRideTheme.light.colorScheme.surface);

    await tester.tap(find.text('Home'));
    expect(tappedPlace?.label, 'Home');
  });

  testWidgets('moves a newly selected default to the first chip', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: EasyRideTheme.light,
        home: Scaffold(
          body: SavedPlaceQuickActionsWidget(
            places: const [
              SavedPlace(
                label: 'Home',
                iconName: 'house',
                latitude: 14.6,
                longitude: 120.98,
              ),
              SavedPlace(
                label: 'Near Bathroom',
                iconName: 'map_pin',
                isDefault: true,
                latitude: 14.61,
                longitude: 120.99,
              ),
            ],
            onPlaceTap: (_) {},
            onAddPlace: () {},
          ),
        ),
      ),
    );

    final nearBathroom = find.text('Near Bathroom');
    final home = find.text('Home');
    expect(
      tester.getTopLeft(nearBathroom).dx,
      lessThan(tester.getTopLeft(home).dx),
    );

    final firstDecoration =
        tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer).at(0))
                .decoration
            as BoxDecoration;
    final secondDecoration =
        tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer).at(1))
                .decoration
            as BoxDecoration;
    expect(firstDecoration.color, EasyRideTheme.light.colorScheme.primary);
    expect(secondDecoration.color, EasyRideTheme.light.colorScheme.surface);
  });
}
