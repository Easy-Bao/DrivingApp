import { and, eq, sql } from 'drizzle-orm';
import { db, postgresClient } from '../shared/drizzle.ts';
import { commissionPolicies, serviceZones } from './schema.ts';

const SOURCE_URL = 'https://psa.gov.ph/classification/psgc/barangays/0907322000';

const PAGADIAN_BARANGAYS = [
  ['0907322001', '097322001', 'Alegria'],
  ['0907322002', '097322002', 'Balangasan'],
  ['0907322003', '097322003', 'Balintawak'],
  ['0907322004', '097322004', 'Baloyboan'],
  ['0907322005', '097322005', 'Banale'],
  ['0907322006', '097322006', 'Bogo'],
  ['0907322007', '097322007', 'Bomba'],
  ['0907322010', '097322010', 'Buenavista'],
  ['0907322011', '097322011', 'Bulatok'],
  ['0907322012', '097322012', 'Bulawan'],
  ['0907322013', '097322013', 'Danlugan'],
  ['0907322014', '097322014', 'Dao'],
  ['0907322015', '097322015', 'Datagan'],
  ['0907322016', '097322016', 'Deborok'],
  ['0907322017', '097322017', 'Ditoray'],
  ['0907322018', '097322018', 'Gatas'],
  ['0907322019', '097322019', 'Gubac'],
  ['0907322020', '097322020', 'Gubang'],
  ['0907322021', '097322021', 'Kagawasan'],
  ['0907322022', '097322022', 'Kahayagan'],
  ['0907322023', '097322023', 'Kalasan'],
  ['0907322024', '097322024', 'La Suerte'],
  ['0907322025', '097322025', 'Lala'],
  ['0907322026', '097322026', 'Lapidian'],
  ['0907322027', '097322027', 'Lenienza'],
  ['0907322028', '097322028', 'Lizon Valley'],
  ['0907322029', '097322029', 'Lourdes'],
  ['0907322030', '097322030', 'Lower Sibatang'],
  ['0907322031', '097322031', 'Lumad'],
  ['0907322032', '097322032', 'Macasing'],
  ['0907322033', '097322033', 'Manga'],
  ['0907322034', '097322034', 'Muricay'],
  ['0907322035', '097322035', 'Napolan'],
  ['0907322036', '097322036', 'Palpalan'],
  ['0907322037', '097322037', 'Pedulonan'],
  ['0907322038', '097322038', 'Poloyagan'],
  ['0907322039', '097322039', 'San Francisco'],
  ['0907322040', '097322040', 'San Jose'],
  ['0907322041', '097322041', 'San Pedro'],
  ['0907322042', '097322042', 'Santa Lucia'],
  ['0907322043', '097322043', 'Santiago'],
  ['0907322044', '097322044', 'Tawagan Sur'],
  ['0907322045', '097322045', 'Tiguma'],
  ['0907322046', '097322046', 'Tuburan'],
  ['0907322047', '097322047', 'Tulawas'],
  ['0907322048', '097322048', 'Tulangan'],
  ['0907322050', '097322050', 'Upper Sibatang'],
  ['0907322051', '097322051', 'White Beach'],
  ['0907322052', '097322052', 'Kawit'],
  ['0907322053', '097322053', 'Lumbia'],
  ['0907322054', '097322054', 'Santa Maria'],
  ['0907322055', '097322055', 'Santo Niño'],
  ['0907322056', '097322056', 'Dampalan'],
  ['0907322057', '097322057', 'Dumagoc'],
] as const;

type BoundaryFeature = {
  type: 'Feature';
  properties: Record<string, unknown>;
  geometry: Record<string, unknown> | null;
};

async function readInterimGeometry(): Promise<Map<string, Record<string, unknown>>> {
  const geometryFile = Bun.file(new URL('./pagadian-barangays.geojson', import.meta.url));
  if (!await geometryFile.exists()) return new Map();

  const collection = await geometryFile.json() as { features?: BoundaryFeature[] };
  return new Map((collection.features ?? []).flatMap((feature) => {
    const rawCode = feature.properties.ADM4_PCODE
      ?? feature.properties.adm4_pcode
      ?? feature.properties.psgc_code
      ?? feature.properties.PSGC_CODE;
    if (!rawCode || !feature.geometry) return [];
    const code = String(rawCode).replace(/^PH/, '');
    return [[code, feature.geometry]];
  }));
}

async function seed() {
  const geometryByCode = await readInterimGeometry();

  await db.transaction(async (transaction) => {
    await transaction.execute(
      sql`select pg_advisory_xact_lock(hashtext('admin-service.seed'))`,
    );

    for (const [psgcCode, correspondenceCode, name] of PAGADIAN_BARANGAYS) {
      const geometry =
        geometryByCode.get(psgcCode) ?? geometryByCode.get(correspondenceCode) ?? null;
      const sourceName = geometryByCode.size > 0
        ? 'UN OCHA HDX Philippines administrative boundaries'
        : 'Philippine Statistics Authority PSGC roster';
      const sourceUrl = geometryByCode.size > 0
        ? 'https://data.humdata.org/dataset/cod-ab-phl'
        : SOURCE_URL;
      const sourceDate =
        geometryByCode.size > 0 ? 'interim; verify before public launch' : '2026-06-30';
      const sourceLicense = geometryByCode.size > 0 ? 'CC BY 3.0 IGO' : 'CC BY 4.0';

      await transaction.insert(serviceZones)
        .values({
          psgcCode,
          correspondenceCode,
          name,
          isActive: false,
          geometry,
          sourceName,
          sourceUrl,
          sourceDate,
          sourceLicense,
        })
        .onConflictDoUpdate({
          target: serviceZones.psgcCode,
          set: {
            correspondenceCode,
            name,
            geometry,
            sourceName,
            sourceUrl,
            sourceDate,
            sourceLicense,
            updatedAt: new Date(),
          },
        });
    }

    const [existingPolicy] = await transaction.select()
      .from(commissionPolicies)
      .where(and(
        eq(commissionPolicies.rateBasisPoints, 1000),
        eq(commissionPolicies.effectiveAt, new Date(0)),
      ))
      .limit(1);
    if (!existingPolicy) {
      await transaction.insert(commissionPolicies).values({
        rateBasisPoints: 1000,
        effectiveAt: new Date(0),
        createdBy: 'system',
        reason: 'Initial BaoBao MVP commission',
      });
    }
  });

  console.log(`Seeded ${PAGADIAN_BARANGAYS.length} Pagadian barangays; ${geometryByCode.size} geometries loaded.`);
}

try {
  await seed();
} finally {
  await postgresClient.end();
}
