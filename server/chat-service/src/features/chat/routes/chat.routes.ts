import { Hono } from 'hono';
import { upgradeWebSocket } from 'hono/bun';
import { zValidator } from '@hono/zod-validator';
import {
  handleCreateChatRoom,
  handleGetChatRoomMessages,
  handleResolveChatRoom,
  handleWebSocketUpgrade,
} from '../controllers/chat.controller.ts';
import {
  createChatRoomSchema,
  resolveChatRoomSchema,
} from '../schemas/chat.schema.ts';

export const chatRouter = new Hono();

chatRouter.post('/rooms', zValidator('json', createChatRoomSchema), handleCreateChatRoom);
chatRouter.get('/rooms/:roomId/messages', handleGetChatRoomMessages);
chatRouter.post('/rooms/:roomId/resolve', zValidator('param', resolveChatRoomSchema), handleResolveChatRoom);
chatRouter.get('/ws', upgradeWebSocket(handleWebSocketUpgrade));
