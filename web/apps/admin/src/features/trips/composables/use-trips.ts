import { ref } from 'vue'

export type TripStatus = 'Completed' | 'In Progress' | 'Dispatching' | 'Cancelled'

export interface TripRecord {
  id: string
  rider: string
  riderPhone: string
  driver: string
  driverPhone: string
  plateNumber: string
  vehicleModel: string
  pickup: string
  dropoff: string
  fare: number
  distanceKm: number
  duration: string
  status: TripStatus
  timestamp: string
}

const initialTrips: TripRecord[] = [
  {
    id: '701629644618921',
    rider: 'Althea Mae Villanueva',
    riderPhone: '+63 935 812 4091',
    driver: 'Rodelio Cruz',
    driverPhone: '+63 917 440 2184',
    plateNumber: '1284-ND',
    vehicleModel: 'Bajaj RE 4S',
    pickup: 'Brgy. San Jose, Pagadian City',
    dropoff: 'Agora Public Market, Poblacion',
    fare: 55.0,
    distanceKm: 3.4,
    duration: '12 mins',
    status: 'In Progress',
    timestamp: '8 mins ago',
  },
  {
    id: '701629644618920',
    rider: 'Carlo Magno Ocampo',
    riderPhone: '+63 917 650 3182',
    driver: 'Danilo Mendoza',
    driverPhone: '+63 928 412 8890',
    plateNumber: '4912-NC',
    vehicleModel: 'TVS King Deluxe',
    pickup: 'Brgy. Gatas, Pagadian City',
    dropoff: "Robinson's Place Pagadian, Tiguma",
    fare: 65.0,
    distanceKm: 4.1,
    duration: '15 mins',
    status: 'Completed',
    timestamp: '19 mins ago',
  },
  {
    id: '701629644618919',
    rider: 'Jessa Mae Lim',
    riderPhone: '+63 926 301 7742',
    driver: 'Reynaldo Garcia',
    driverPhone: '+63 908 771 9923',
    plateNumber: '9021-ND',
    vehicleModel: 'Bajaj RE FI',
    pickup: 'Pagadian Integrated Bus Terminal',
    dropoff: 'Zamboanga del Sur Medical Center, Dao',
    fare: 85.0,
    distanceKm: 5.6,
    duration: '19 mins',
    status: 'Completed',
    timestamp: '42 mins ago',
  },
  {
    id: '701629644618918',
    rider: 'Mark Anthony Reyes',
    riderPhone: '+63 945 204 8810',
    driver: 'Unassigned',
    driverPhone: '—',
    plateNumber: 'Pending',
    vehicleModel: 'Bao-Bao',
    pickup: 'Santiago District, Pagadian City',
    dropoff: 'Provincial Capitol Complex, Balangasan',
    fare: 50.0,
    distanceKm: 2.9,
    duration: '—',
    status: 'Dispatching',
    timestamp: '2 mins ago',
  },
  {
    id: '701629644618917',
    rider: 'Kristine Joy Navarro',
    riderPhone: '+63 998 411 6620',
    driver: 'Maria Lourdes Ramos',
    driverPhone: '+63 920 882 1144',
    plateNumber: '3391-ND',
    vehicleModel: 'Bajaj Maxima Z (Bao-Bao)',
    pickup: 'Brgy. Santa Lucia, Pagadian City',
    dropoff: 'Pagadian City Rotunda',
    fare: 45.0,
    distanceKm: 2.4,
    duration: '—',
    status: 'Cancelled',
    timestamp: '2 hours ago',
  },
  {
    id: '701629644618916',
    rider: 'Clarisse Abella',
    riderPhone: '+63 917 440 2184',
    driver: 'Eduardo Santos',
    driverPhone: '+63 916 332 9012',
    plateNumber: '7712-NC',
    vehicleModel: 'Piaggio Ape City (Bao-Bao)',
    pickup: 'Gaisano Capital Pagadian, San Pedro',
    dropoff: 'Brgy. Kawit Wharf',
    fare: 60.0,
    distanceKm: 3.8,
    duration: '14 mins',
    status: 'Completed',
    timestamp: '2 hours ago',
  },
  {
    id: '701629644618915',
    rider: 'Paulo Miguel Torres',
    riderPhone: '+63 918 511 4902',
    driver: 'Brandon Lee',
    driverPhone: '+63 921 670 3311',
    plateNumber: '3891-ZK',
    vehicleModel: 'Bajaj RE 4S',
    pickup: 'Southern Mindanao Colleges, San Francisco',
    dropoff: 'Brgy. Sto. Nino Junction',
    fare: 40.0,
    distanceKm: 2.1,
    duration: '9 mins',
    status: 'Completed',
    timestamp: '3 hours ago',
  },
  {
    id: '701629644618914',
    rider: 'Shiela Marie Dizon',
    riderPhone: '+63 905 741 2289',
    driver: 'Edgar Tolentino',
    driverPhone: '+63 919 845 7710',
    plateNumber: '5190-QP',
    vehicleModel: 'E-BaoBao Pioneer (Electric)',
    pickup: 'Plaza Luzon Oval, Gatas',
    dropoff: 'Brgy. Dumagoc Coastal Road',
    fare: 70.0,
    distanceKm: 4.5,
    duration: '16 mins',
    status: 'In Progress',
    timestamp: '11 mins ago',
  },
  {
    id: '701629644618913',
    rider: 'Nathaniel Pineda',
    riderPhone: '+63 927 603 1185',
    driver: 'Rodelio Cruz',
    driverPhone: '+63 917 440 2184',
    plateNumber: '1284-ND',
    vehicleModel: 'Bajaj RE 4S',
    pickup: 'Pagadian City Hall, Dao',
    dropoff: 'Agora Public Market, Poblacion',
    fare: 75.0,
    distanceKm: 4.9,
    duration: '17 mins',
    status: 'Completed',
    timestamp: '4 hours ago',
  },
  {
    id: '701629644618912',
    rider: 'Grace Cabading',
    riderPhone: '+63 915 209 7741',
    driver: 'Danilo Mendoza',
    driverPhone: '+63 928 412 8890',
    plateNumber: '4912-NC',
    vehicleModel: 'TVS King Deluxe',
    pickup: 'Brgy. Tuburan Hall',
    dropoff: 'Pagadian Airport Gate, Muricay',
    fare: 120.0,
    distanceKm: 7.8,
    duration: '24 mins',
    status: 'Completed',
    timestamp: '5 hours ago',
  },
  {
    id: '701629644618911',
    rider: 'Marco Villanueva',
    riderPhone: '+63 928 715 3390',
    driver: 'Unassigned',
    driverPhone: '—',
    plateNumber: 'Pending',
    vehicleModel: 'Bao-Bao',
    pickup: 'Brgy. Buenavista Highway',
    dropoff: 'Saint Columban College, San Francisco',
    fare: 55.0,
    distanceKm: 3.3,
    duration: '—',
    status: 'Dispatching',
    timestamp: '4 mins ago',
  },
  {
    id: '701629644618910',
    rider: 'Teresita Bautista',
    riderPhone: '+63 995 318 6024',
    driver: 'Reynaldo Garcia',
    driverPhone: '+63 908 771 9923',
    plateNumber: '9021-ND',
    vehicleModel: 'Bajaj RE FI',
    pickup: 'Brgy. Lumbia Junction',
    dropoff: 'Hofileña Memorial Hospital',
    fare: 60.0,
    distanceKm: 3.6,
    duration: '13 mins',
    status: 'Completed',
    timestamp: '6 hours ago',
  },
]

export function tripStatusTone(status: TripStatus) {
  if (status === 'Completed') return 'success' as const
  if (status === 'In Progress') return 'info' as const
  if (status === 'Dispatching') return 'warning' as const
  return 'danger' as const
}

export function useTrips() {
  const trips = ref<TripRecord[]>(initialTrips.map((item) => ({ ...item })))

  return {
    trips,
    tripStatusTone,
  }
}
