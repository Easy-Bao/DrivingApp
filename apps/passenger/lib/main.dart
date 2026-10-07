import 'package:passenger/src/app/passenger_bootstrap.dart';

Future<void> main() => bootstrapPassengerApp();

/*
TODO (manual deployment verification):

- Build and install signed release APKs for Passenger and Driver.
- Exercise the release flows on a physical Android device over USB and LAN.

The source-level deployment audit is complete; these checks require a release
keystore, a reachable backend, and hardware that are not available to this run.
*/

/// use patrol for e2e testing
