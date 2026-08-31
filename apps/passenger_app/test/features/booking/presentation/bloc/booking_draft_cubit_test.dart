import 'package:flutter_test/flutter_test.dart';
import 'package:maps/maps.dart';
import 'package:passenger_app/src/features/booking/presentation/bloc/booking_draft/booking_draft_cubit.dart';
import 'package:passenger_app/src/features/booking/domain/entities/booking_draft.dart';

void main() {
  const destination = Place(
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
