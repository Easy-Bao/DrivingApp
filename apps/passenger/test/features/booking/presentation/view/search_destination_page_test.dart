import 'package:flutter_test/flutter_test.dart';
import 'package:passenger/src/features/booking/presentation/view/search_destination_page.dart';

void main() {
  test(
    'destination search keeps the rate-limit debounce at 300 milliseconds',
    () {
      expect(
        SearchDestinationPage.searchDebounceDuration,
        const Duration(milliseconds: 300),
      );
    },
  );
}
