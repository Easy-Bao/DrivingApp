import { PrismaClient } from '@prisma/client';

let _prisma: PrismaClient | null = null;

export const prisma = new Proxy({} as PrismaClient, {
  get(_target, prop, receiver) {
    if (!_prisma) {
      _prisma = new PrismaClient();
    }
    return Reflect.get(_prisma, prop, receiver);
  }
});
