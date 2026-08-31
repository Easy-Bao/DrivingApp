import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:passenger_app/src/features/saved_places/presentation/bloc/saved_places/saved_places_cubit.dart';
import 'package:passenger_app/src/features/saved_places/domain/repositories/i_saved_places_repository.dart';
import 'package:passenger_app/src/features/saved_places/presentation/saved_place_page.dart';

class MockSavedPlacesRepository extends Mock
    implements ISavedPlacesRepository {}

void main() {
  testWidgets('allows choosing the only Home quick action', (
    WidgetTester tester,
  ) async {
    final repository = MockSavedPlacesRepository();
    when(() => repository.loadPlaces()).thenAnswer(
      (_) async => <Map<String, dynamic>>[
        {'label': 'Home', 'iconName': 'house', 'isDefault': true},
        {'label': 'Near Bathroom', 'iconName': 'map_pin'},
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

    await tester.tap(find.text('Near Bathroom'));
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
}
