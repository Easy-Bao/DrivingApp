import { prisma } from '../db.ts';

export const activeConnections = new Map<string, Set<any>>();

export async function upsertRoom(roomId: string, driverId: string, passengerId: string) {
  return await prisma.room.upsert({
    where: { id: roomId },
    update: {},
    create: {
      id: roomId,
      driverId,
      passengerId,
    },
  });
}

export async function getRoomMessages(roomId: string) {
  return await prisma.message.findMany({
    where: { roomId },
    orderBy: { createdAt: 'asc' },
  });
}

export async function getRoomDetails(roomId: string) {
  return await prisma.room.findUnique({
    where: { id: roomId },
  });
}

export async function addMessageToHistory(roomId: string, senderId: string, text: string) {
  return await prisma.message.create({
    data: {
      roomId,
      senderId,
      message: text,
    },
  });
}

export async function getRecentRoomMessages(roomId: string, limit = 50) {
  return await prisma.message.findMany({
    where: { roomId },
    orderBy: { createdAt: 'asc' },
    take: limit,
  });
}
