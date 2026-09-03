import assert from 'node:assert/strict';
import test from 'node:test';
import {
  attachRideStatusListener,
  createRideSocketNotificationEngine,
} from '../src/realtime/socket_io_ride_notification_engine.js';

function createIoHarness() {
  const middleware = [];
  const handlers = new Map();
  const emitted = [];
  return {
    middleware,
    handlers,
    emitted,
    use(handler) { middleware.push(handler); },
    on(event, handler) { handlers.set(event, handler); },
    to(room) { return { emit: (event, payload) => emitted.push({ room, event, payload }) }; },
  };
}

test('authenticated passengers join only their user room', async () => {
  const io = createIoHarness();
  createRideSocketNotificationEngine({ io, verifyIdToken: async () => ({ uid: 'passenger-1', role: 'passenger' }) });
  const socket = { handshake: { auth: { token: 'jwt' } }, data: {}, rooms: [], join(room) { this.rooms.push(room); }, emit() {} };
  await new Promise((resolve, reject) => io.middleware[0](socket, (error) => error ? reject(error) : resolve()));
  io.handlers.get('connection')(socket);
  assert.deepEqual(socket.rooms, ['user_passenger-1']);
});

test('authenticated drivers join their user and driver rooms', async () => {
  const io = createIoHarness();
  createRideSocketNotificationEngine({ io, verifyIdToken: async () => ({ uid: 'driver-1', role: 'driver' }) });
  const socket = { handshake: { auth: { token: 'jwt' } }, data: {}, rooms: [], join(room) { this.rooms.push(room); }, emit() {} };
  await new Promise((resolve, reject) => io.middleware[0](socket, (error) => error ? reject(error) : resolve()));
  io.handlers.get('connection')(socket);
  assert.deepEqual(socket.rooms, ['user_driver-1', 'driver_driver-1']);
});

test('ride milestones emit only to the assigned passenger and driver rooms', () => {
  const io = createIoHarness();
  const engine = createRideSocketNotificationEngine({ io, verifyIdToken: async () => ({ uid: 'unused' }), now: () => 123 });
  engine.emitForRideStatus({ rideId: 'ride-1', userId: 'passenger-1', driverId: 'driver-1', status: 'driver_arrived' });
  assert.deepEqual(io.emitted.map(({ room, event }) => ({ room, event })), [
    { room: 'user_passenger-1', event: 'driver_arrived' },
    { room: 'driver_driver-1', event: 'driver_arrived' },
  ]);
  assert.equal(io.emitted[0].payload.occurredAtMs, 123);
});

test('Firestore ride status changes invoke the matching socket milestone once', () => {
  let snapshotListener;
  const emitted = [];
  const firestore = {
    collection() {
      return {
        onSnapshot(listener) {
          snapshotListener = listener;
          return () => {};
        },
      };
    },
  };
  attachRideStatusListener({
    firestore,
    notificationEngine: { emitForRideStatus: (ride) => emitted.push(ride) },
    logger: { error() {} },
  });

  const ride = { rideId: 'ride-1', userId: 'passenger-1', driverId: 'driver-1', status: 'driver_assigned' };
  snapshotListener({ docChanges: () => [{ type: 'added', doc: { id: 'ride-1', data: () => ride } }] });
  snapshotListener({ docChanges: () => [{ type: 'modified', doc: { id: 'ride-1', data: () => ride } }] });
  snapshotListener({ docChanges: () => [{ type: 'modified', doc: { id: 'ride-1', data: () => ({ ...ride, status: 'driver_arrived' }) } }] });

  assert.deepEqual(emitted, [{ ...ride, status: 'driver_arrived' }]);
});