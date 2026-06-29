/**
 * Database client initializer: sets up the Prisma Client and applies database schema migrations dynamically if a PostgreSQL URL is configured.
 */
import { PrismaClient } from '@prisma/client';
import * as fs from 'fs';
import * as path from 'path';

export const prisma = new PrismaClient();

export async function runMigrations() {
  if (!process.env.DATABASE_URL) {
    return;
  }

  try {
    const tableExists = await prisma.$queryRaw<Array<{ exists: boolean }>>`
      SELECT EXISTS (
        SELECT FROM pg_tables 
        WHERE schemaname = 'public' 
        AND tablename = 'passengers'
      );
    `;

    if (!tableExists[0]?.exists) {
      const initSqlPath = path.join(__dirname, '../migrations/20260626000000_create_passenger_tables.sql');
      const initSql = fs.readFileSync(initSqlPath, 'utf8');
      await prisma.$executeRawUnsafe(initSql);
    }

    const columnExists = await prisma.$queryRaw<Array<{ exists: boolean }>>`
      SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'passengers' 
        AND column_name = 'password_hash'
      );
    `;

    if (!columnExists[0]?.exists) {
      const hashSqlPath = path.join(__dirname, '../migrations/20260627000000_add_password_hash.sql');
      const hashSql = fs.readFileSync(hashSqlPath, 'utf8');
      await prisma.$executeRawUnsafe(hashSql);
    }
  } catch (error) {
    console.error('Migration failed:', error);
  }
}
