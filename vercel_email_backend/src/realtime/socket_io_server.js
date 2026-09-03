import { Server } from 'socket.io';
import {
  attachRideStatusListener,
  createRideSocketNotificationEngine,
} from './socket_io_ride_notification_engine.js';

export function attachRideSocketServer({
  httpServer,
  verifyIdToken,
  corsOrigin,
  firestore,
} = {}) {
  if (!httpServer) throw new Error('An HTTP server is required.');

  const io = new Server(httpServer, {
    cors: {
      origin: corsOrigin,
      methods: ['GET', 'POST'],
    },
    transports: ['websocket'],
  });

  const notificationEngine = createRideSocketNotificationEngine({
    io,
    verifyIdToken,
  });
  const unsubscribeRideStatus = firestore
    ? attachRideStatusListener({ firestore, notificationEngine })
    : null;

  return Object.freeze({
    ...notificationEngine,
    close() {
      unsubscribeRideStatus?.();
      io.close();
    },
  });
}