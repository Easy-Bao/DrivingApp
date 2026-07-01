/// Database client initializer: sets up the Prisma Client singleton for bidding-service.
import { PrismaClient } from '@prisma/client';

export const prisma = new PrismaClient();
