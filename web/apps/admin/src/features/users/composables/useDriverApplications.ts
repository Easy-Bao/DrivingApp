import { ref } from 'vue'

export interface DriverApplication {
  id: string
  applicant: string
  email: string
  phone: string
  appliedDate: string
  city: string
  licenseNumber: string
  licenseExpiry: string
  licenseDoc: string
  vehicle: {
    make: string
    model: string
    year: number
    plate: string
    color: string
    vin: string
    insurancePolicy: string
    inspectionDoc: string
  }
  backgroundStatus: 'Passed' | 'Pending' | 'Review Required'
  backgroundProvider: string
  backgroundNotes: string
  status: 'Pending Review' | 'Approved' | 'Rejected'
}

const applications = ref<DriverApplication[]>([
  {
    id: 'APP-901',
    applicant: 'Brandon Lee',
    email: 'brandon.lee@metroflow.io',
    phone: '+1 (555) 111-2233',
    appliedDate: '2 hours ago',
    city: 'Metro Core',
    licenseNumber: 'DL-99210-CA',
    licenseExpiry: '2028-09-15',
    licenseDoc: 'drivers_license_brandon_lee.pdf',
    vehicle: {
      make: 'Tesla',
      model: 'Model 3 Standard Range',
      year: 2023,
      plate: '7XYZ892',
      color: 'Midnight Silver',
      vin: '5YJ3E1EB9PF182901',
      insurancePolicy: 'StateFarm Policy #9921-8841-A',
      inspectionDoc: 'annual_safety_inspection_2026.pdf',
    },
    backgroundStatus: 'Passed',
    backgroundProvider: 'Checkr Regulatory API',
    backgroundNotes:
      'Zero criminal records, clean driving history past 7 years, verified active SSN.',
    status: 'Pending Review',
  },
  {
    id: 'APP-902',
    applicant: 'Fatima Al-Mansoor',
    email: 'fatima.almansoor@fleetline.net',
    phone: '+1 (555) 444-5566',
    appliedDate: '5 hours ago',
    city: 'North District',
    licenseNumber: 'DL-44819-CA',
    licenseExpiry: '2027-04-20',
    licenseDoc: 'drivers_license_fatima.pdf',
    vehicle: {
      make: 'Toyota',
      model: 'Prius Hybrid',
      year: 2022,
      plate: 'EV-4491',
      color: 'Super White',
      vin: 'JTDKN3DU5N0192834',
      insurancePolicy: 'Geico Commercial #8819-0021-B',
      inspectionDoc: 'state_vehicle_cert_2026.pdf',
    },
    backgroundStatus: 'Pending',
    backgroundProvider: 'Checkr Regulatory API',
    backgroundNotes: 'Awaiting final DMV motor vehicle record check from jurisdiction registry.',
    status: 'Pending Review',
  },
  {
    id: 'APP-903',
    applicant: 'Tyler Brooks',
    email: 'tyler.brooks@transithub.org',
    phone: '+1 (555) 777-8899',
    appliedDate: 'Yesterday',
    city: 'Westside',
    licenseNumber: 'DL-88192-CA',
    licenseExpiry: '2029-01-30',
    licenseDoc: 'drivers_license_tyler.pdf',
    vehicle: {
      make: 'Chevrolet',
      model: 'Bolt EV',
      year: 2024,
      plate: 'CAM-8891',
      color: 'Mosaic Black',
      vin: '1G1FX6S07P4109283',
      insurancePolicy: 'Progressive Fleet #0912-3841-C',
      inspectionDoc: 'ev_battery_brake_cert_2026.pdf',
    },
    backgroundStatus: 'Passed',
    backgroundProvider: 'Checkr Regulatory API',
    backgroundNotes: 'Identity confirmed, zero infractions, background check cleared.',
    status: 'Pending Review',
  },
])

export function useDriverApplications() {
  function getApplicationById(id: string): DriverApplication | undefined {
    return applications.value.find((a) => a.id === id)
  }

  function approveApplication(app: DriverApplication): void {
    app.status = 'Approved'
  }

  function rejectApplication(app: DriverApplication, _reason?: string): void {
    app.status = 'Rejected'
  }

  return {
    applications,
    getApplicationById,
    approveApplication,
    rejectApplication,
  }
}
