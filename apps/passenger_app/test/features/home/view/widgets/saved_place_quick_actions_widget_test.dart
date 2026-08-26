import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/home/view/widgets/saved_place_quick_actions_widget.dart';
import 'package:passenger_app/src/features/saved_places/domain/entities/saved_place.dart';

void main() {
  testWidgets('renders only the selected default place and Add place', (
    WidgetTester tester,
  ) async {
    SavedPlace? tappedPlace;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SavedPlaceQuickActionsWidget(
            places: const [
              SavedPlace(label: 'Home', iconName: 'house', isDefault: true),
              SavedPlace(label: 'Near Bathroom', iconName: 'map_pin'),
            ],
            onPlaceTap: (place) => tappedPlace = place,
            onAddPlace: () {},
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Near Bathroom'), findsNothing);
    expect(find.text('Add place'), findsOneWidget);

    await tester.tap(find.text('Home'));
    expect(tappedPlace?.label, 'Home');
  });
}
