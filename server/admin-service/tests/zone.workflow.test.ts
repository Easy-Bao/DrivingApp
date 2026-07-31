import { describe, expect, test } from 'bun:test';
import { AdminClients } from '../src/features/clients/admin.clients.ts';
import { AdminRepository } from '../src/features/repositories/admin.repository.ts';
import { AdminService } from '../src/features/services/admin.service.ts';

const activeZone = {
  psgcCode: 'PH0907322018',
  name: 'Gatas',
  isActive: true,
  geometry: {
    type: 'Polygon' as const,
    coordinates: [[
      [123, 7],
      [124, 7],
      [124, 8],
      [123, 8],
      [123, 7],
    ]],
  },
};

function serviceWithZones(zones: typeof activeZone[]) {
  return new AdminService(
    { listActiveZones: async () => zones } as unknown as AdminRepository,
    {} as AdminClients,
  );
}

describe('Admin service-zone workflow', () => {
  test('fails closed while no pilot barangay is active', async () => {
    expect(await serviceWithZones([]).checkZones({
      pickupLatitude: 7.5,
      pickupLongitude: 123.5,
      dropoffLatitude: 7.6,
      dropoffLongitude: 123.6,
    })).toEqual({
      allowed: false,
      code: 'SERVICE_ZONE_NOT_CONFIGURED',
      message: 'No Pagadian pilot barangays are active.',
    });
  });

  test('requires both pickup and destination to be inside active geometry', async () => {
    const service = serviceWithZones([activeZone]);
    const allowed = await service.checkZones({
      pickupLatitude: 7.5,
      pickupLongitude: 123.5,
      dropoffLatitude: 7.6,
      dropoffLongitude: 123.6,
    });
    const outsideDropoff = await service.checkZones({
      pickupLatitude: 7.5,
      pickupLongitude: 123.5,
      dropoffLatitude: 9,
      dropoffLongitude: 125,
    });
    const outsidePickup = await service.checkZones({
      pickupLatitude: 9,
      pickupLongitude: 125,
      dropoffLatitude: 7.6,
      dropoffLongitude: 123.6,
    });

    expect(allowed).toMatchObject({
      allowed: true,
      code: 'ALLOWED',
      pickup_zone: { psgc_code: 'PH0907322018', name: 'Gatas' },
      dropoff_zone: { psgc_code: 'PH0907322018', name: 'Gatas' },
    });
    expect(outsideDropoff).toMatchObject({
      allowed: false,
      code: 'OUTSIDE_SERVICE_ZONE',
      pickup_zone: { psgc_code: 'PH0907322018' },
      dropoff_zone: null,
    });
    expect(outsidePickup).toMatchObject({
      allowed: false,
      code: 'OUTSIDE_SERVICE_ZONE',
      pickup_zone: null,
      dropoff_zone: { psgc_code: 'PH0907322018' },
    });
  });
});
