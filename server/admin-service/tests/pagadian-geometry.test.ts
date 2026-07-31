import { describe, expect, test } from 'bun:test';
import { isPointInZone, ZoneGeometry } from '../src/features/services/zone.service.ts';

type BoundaryFeature = {
  properties: {
    adm4_name: string;
    adm4_pcode: string;
  };
  geometry: ZoneGeometry;
};

const collection = await Bun.file(
  new URL('../src/db/pagadian-barangays.geojson', import.meta.url),
).json() as { features: BoundaryFeature[] };

describe('Pagadian interim boundary data', () => {
  test('contains exactly 54 uniquely coded barangays', () => {
    expect(collection.features).toHaveLength(54);
    expect(new Set(
      collection.features.map((feature) => feature.properties.adm4_pcode),
    ).size).toBe(54);
  });

  test('accepts the HDX center of Gatas and rejects a distant point', () => {
    const gatas = collection.features.find(
      (feature) => feature.properties.adm4_pcode === 'PH0907322018',
    );
    expect(gatas).toBeDefined();
    expect(isPointInZone([123.43561697, 7.82578102], gatas!.geometry)).toBe(true);
    expect(isPointInZone([122, 7], gatas!.geometry)).toBe(false);
  });
});
