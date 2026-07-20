import { z } from 'zod';

export const createChatRoomSchema = z.object({
  roomId: z.string().min(1, 'roomId is required'),
  driverId: z.string().min(1, 'driverId is required'),
  passengerId: z.string().min(1, 'passengerId is required'),
});

export const resolveChatRoomSchema = z.object({
  roomId: z.string().min(1, 'roomId is required'),
});
