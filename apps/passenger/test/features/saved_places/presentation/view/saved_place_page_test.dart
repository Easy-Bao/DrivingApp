import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger/src/features/saved_places/domain/entities/saved_place.dart';
import 'package:passenger/src/features/saved_places/domain/repositories/saved_places_repository.dart';
import 'package:passenger/src/features/saved_places/presentation/bloc/saved_places/saved_places_cubit.dart';
import 'package:passenger/src/features/saved_places/presentation/view/saved_place_page.dart';

class MockSavedPlacesRepository extends Mock implements SavedPlacesRepository {}

void main() {
  testWidgets('allows choosing the only Home quick action', (
    WidgetTester tester,
  ) async {
    final repository = MockSavedPlacesRepository();
    when(() => repository.loadPlaces()).thenAnswer(
      (_) async => const <SavedPlace>[
        SavedPlace(label: 'Home', iconName: 'house', isDefault: true),
        SavedPlace(label: 'Near Bathroom', iconName: 'map_pin'),
      ],
    );
    when(() => repository.savePlaces(any())).thenAnswer((_) async {});
    final cubit = SavedPlacesCubit(repository: repository);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const SavedPlacePage()),
      ),
    );
    await tester.pumpAndSettle();

    final nearBathroom = find.byKey(
      const ValueKey<String>('saved-place-Near Bathroom'),
    );
    await tester.scrollUntilVisible(nearBathroom, 300);
    await tester.tap(nearBathroom);
    await tester.pumpAndSettle();

    final setDefaultAction = find.text('Set as Home quick action');
    expect(setDefaultAction, findsOneWidget);
    await tester.tap(setDefaultAction);
    await tester.pumpAndSettle();

    expect(cubit.state.defaultPlace?.label, 'Near Bathroom');
    expect(cubit.state.places.where((place) => place.isDefault), hasLength(1));
    expect(find.text('Default'), findsOneWidget);

    await cubit.close();
  });

  testWidgets('keeps the redesigned shortcuts usable on a narrow screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = MockSavedPlacesRepository();
    when(() => repository.loadPlaces()).thenAnswer(
      (_) async => const <SavedPlace>[
        SavedPlace(
          label: 'Home',
          iconName: 'house',
          savedAddress: 'Near Bathroom, Mountain View',
          latitude: 37.3861,
          longitude: -122.0839,
        ),
        SavedPlace(label: 'Work', iconName: 'briefcase'),
        SavedPlace(
          label: 'Near Bathroom',
          iconName: 'map_pin',
          savedAddress: '1600 Amphitheatre Parkway, Mountain View',
          latitude: 37.422,
          longitude: -122.084,
          isDefault: true,
        ),
      ],
    );
    when(() => repository.savePlaces(any())).thenAnswer((_) async {});
    final cubit = SavedPlacesCubit(repository: repository);
    addTearDown(cubit.close);

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const SavedPlacePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Saved places'), findsOneWidget);
    expect(
      find.text('Your everyday destinations, one tap away.'),
      findsNothing,
    );
    expect(find.text('Save the places you go often'), findsNothing);
    expect(find.text('Everyday shortcuts'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('saved-places-scroll')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
