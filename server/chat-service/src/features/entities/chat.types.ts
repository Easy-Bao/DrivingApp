export interface ChatRoom {
  id: string;
  driverId: string;
  passengerId: string;
  createdAt: Date;
  resolved: boolean;
}

export interface ChatMessage {
  id: string;
  roomId: string;
  senderId: string;
  message: string;
  createdAt: Date;
}
