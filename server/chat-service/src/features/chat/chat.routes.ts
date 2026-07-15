/**
 * Routing definitions mapping endpoint URIs to respective feature controller actions.
 */
import { Hono } from 'hono';
import { upgradeWebSocket } from 'hono/bun';
import {
  handleCreateChatRoom,
  handleGetChatRoomMessages,
  handleResolveChatRoom,
  handleWebSocketUpgrade,
} from './chat.controller.ts';

export const chatRouter = new Hono();

chatRouter.post('/rooms', handleCreateChatRoom);
chatRouter.get('/rooms/:roomId/messages', handleGetChatRoomMessages);
chatRouter.post('/rooms/:roomId/resolve', handleResolveChatRoom);
chatRouter.get('/ws', upgradeWebSocket(handleWebSocketUpgrade));
