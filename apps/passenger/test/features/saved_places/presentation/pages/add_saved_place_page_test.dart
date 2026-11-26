import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:maps/maps.dart';
import 'package:material_ui/material_ui.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/presentation/pages/add_saved_place_page.dart';

void main() {
  testWidgets(
    'validates name inline, allows icon selection without OS splash, and pops SavedPlace',
    (tester) async {
      SavedPlace? savedPlace;
      const place = Place(
        id: 'place-1',
        name: 'Coffee Lab',
        fullAddress: '123 Bonifacio High St, Taguig',
        latitude: 14.5505,
        longitude: 121.0509,
      );

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async {
                    savedPlace = await context.push<SavedPlace>('/add');
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/add',
            builder: (context, state) => AddCategoryPage(
              initialPlace: place,
              mapPreviewBuilder: (_) =>
                  const ColoredBox(color: Colors.transparent),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.main, routerConfig: router),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('123 Bonifacio High St, Taguig'), findsOneWidget);

      final nameField = find.byKey(
        const ValueKey<String>('add-place-name-field'),
      );
      await tester.enterText(nameField, '   ');
      await tester.tap(find.byKey(const ValueKey<String>('add-place-save')));
      await tester.pump();
      expect(find.text('Enter a name for this place.'), findsOneWidget);

      await tester.enterText(nameField, 'Favorite Cafe');
      await tester.pump();
      expect(find.text('Enter a name for this place.'), findsNothing);

      final starOption = find.byKey(
        const ValueKey<String>('add-place-icon-star'),
      );
      final starInkWell = tester.widget<InkWell>(starOption);
      expect(starInkWell.enableFeedback, isFalse);
      expect(starInkWell.splashFactory, NoSplash.splashFactory);

      await tester.tap(starOption);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('add-place-save')));
      await tester.pumpAndSettle();

      expect(savedPlace, isNotNull);
      expect(savedPlace!.label, 'Favorite Cafe');
      expect(savedPlace!.iconName, 'star');
      expect(savedPlace!.savedAddress, '123 Bonifacio High St, Taguig');
      expect(tester.takeException(), isNull);
    },
  );
}
