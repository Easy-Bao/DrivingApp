import { createReadStream } from 'node:fs';
import { createInterface } from 'node:readline';

const [inputPath, outputPath] = process.argv.slice(2);
if (!inputPath || !outputPath) {
  throw new Error(
    'Usage: bun scripts/extract-pagadian-geometry.ts <phl_admin4.geojson> <output.geojson>',
  );
}

const features: Array<Record<string, unknown>> = [];
const lines = createInterface({
  input: createReadStream(inputPath, { encoding: 'utf8' }),
  crlfDelay: Infinity,
});

for await (const line of lines) {
  if (!line.includes('"adm3_pcode":"PH0907322"')) continue;
  const feature = JSON.parse(line.replace(/,\s*$/, '')) as {
    type: string;
    properties: Record<string, unknown>;
    geometry: Record<string, unknown>;
  };
  features.push({
    type: feature.type,
    properties: {
      adm4_name: feature.properties.adm4_name,
      adm4_pcode: feature.properties.adm4_pcode,
      adm3_name: feature.properties.adm3_name,
      adm3_pcode: feature.properties.adm3_pcode,
      valid_on: feature.properties.valid_on,
      version: feature.properties.version,
    },
    geometry: feature.geometry,
  });
}

if (features.length !== 54) {
  throw new Error(`Expected 54 Pagadian barangays, found ${features.length}.`);
}

await Bun.write(outputPath, JSON.stringify({
  type: 'FeatureCollection',
  name: 'Pagadian City barangay boundaries (HDX/OCHA interim development data)',
  source: 'https://data.humdata.org/dataset/cod-ab-phl',
  features,
}, null, 2));

console.log(`Wrote ${features.length} Pagadian barangay features to ${outputPath}.`);
