import { db } from './src/shared/drizzle.ts';
import { drivers, reviews } from './src/db/schema.ts';

async function main() {
  try {
    await db.delete(reviews);
    await db.delete(drivers);
    console.log('Successfully cleared all drivers and reviews from database.');
  } catch (error) {
    console.error('Failed to clear database:', error);
  } finally {
    process.exit(0);
  }
}

main();
