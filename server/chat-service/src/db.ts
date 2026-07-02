/// Database client: instantiates global PrismaClient for query execution.
import { PrismaClient } from '@prisma/client';

export const prisma = new PrismaClient();
