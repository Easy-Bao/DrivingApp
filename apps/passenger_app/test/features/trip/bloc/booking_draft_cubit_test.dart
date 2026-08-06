import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/src/features/trip/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger_app/src/features/trip/domain/entities/booking_draft.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  const destination = PlaceModel(
    id: 'destination-1',
    name: 'J.H. Cerilles State College',
    fullAddress: 'Mahayag Road, Pagadian City',
    latitude: 7.8282,
    longitude: 123.4361,
  );

  test('stores and clears the guest booking draft', () async {
    final cubit = BookingDraftCubit();
    const draft = BookingDraft(
      destination: destination,
      pickupAddress: 'Tuburan, Pagadian City',
    );

    cubit.save(draft);
    expect(cubit.state.draft, draft);

    cubit.clear();
    expect(cubit.state.hasDraft, isFalse);

    await cubit.close();
  });
}
