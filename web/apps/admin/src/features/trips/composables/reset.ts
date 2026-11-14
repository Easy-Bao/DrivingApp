import { resetTripRecordsForTesting } from '@/features/trips/composables/use-trips'
import { resetDispatchForTesting } from '@/features/trips/composables/use-dispatch'
import { resetSafetyForTesting } from '@/features/trips/composables/use-safety'

export function resetTripsForTesting() {
  resetTripRecordsForTesting()
  resetDispatchForTesting()
  resetSafetyForTesting()
}
