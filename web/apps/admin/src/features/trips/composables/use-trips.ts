import { computed, ref } from 'vue'
import { SEED_TRIPS } from '@/features/trips/data/trips.seed'
import type { TripRecord, TripStatus } from '@/features/trips/types'
import type { BadgeTone } from '@/shared'

function cloneTrips(source: readonly TripRecord[]): TripRecord[] {
  return source.map((item) => ({ ...item }))
}

export const tripsRef = ref<TripRecord[]>(cloneTrips(SEED_TRIPS))

export function tripStatusTone(status: TripStatus): BadgeTone {
  if (status === 'Completed') return 'success'
  if (status === 'In Progress') return 'info'
  if (status === 'Dispatching') return 'warning'
  return 'danger'
}

export function resetTripRecordsForTesting() {
  tripsRef.value = cloneTrips(SEED_TRIPS)
}

export function useTrips() {
  const completedCount = computed(
    () => tripsRef.value.filter((trip) => trip.status === 'Completed').length,
  )

  const activeCount = computed(
    () =>
      tripsRef.value.filter(
        (trip) => trip.status === 'In Progress' || trip.status === 'Dispatching',
      ).length,
  )

  const averageFareCentavos = computed(() => {
    if (tripsRef.value.length === 0) return 0
    const total = tripsRef.value.reduce((sum, trip) => sum + trip.fareCentavos, 0)
    return Math.round(total / tripsRef.value.length)
  })

  const completionRateLabel = computed(() => {
    const resolved = tripsRef.value.filter(
      (trip) => trip.status === 'Completed' || trip.status === 'Cancelled',
    ).length
    if (resolved === 0) return '0.0%'
    return `${((completedCount.value / resolved) * 100).toFixed(1)}%`
  })

  return {
    trips: tripsRef,
    completedCount,
    activeCount,
    averageFareCentavos,
    completionRateLabel,
    tripStatusTone,
  }
}
