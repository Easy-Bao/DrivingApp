import 'package:flutter_bloc/flutter_bloc.dart';
import 'passenger_home_state.dart';

class PassengerHomeCubit extends Cubit<PassengerHomeState> {
  PassengerHomeCubit()
    : super(
        const PassengerHomeInitial(address: "Pagadian City, Zamboanga del Sur"),
      );

  void updateLocation(String newAddress) {
    emit(PassengerHomeLoaded(address: newAddress));
  }
}
