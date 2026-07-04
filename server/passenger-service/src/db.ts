/**
 * Database client initializer: sets up the Prisma Client instance.
 */
import { PrismaClient } from '@prisma/client';

let _prisma: PrismaClient | null = null;

export const prisma = new Proxy({} as PrismaClient, {
  get(target, prop, receiver) {
    if (!_prisma) {
      _prisma = new PrismaClient();
    }
    return Reflect.get(_prisma, prop, receiver);
  }
});
