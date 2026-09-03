const RIDE_MILESTONE_EVENTS = Object.freeze([
  'ride_requested',
  'ride_accepted',
  'driver_arrived',
  'trip_started',
  'trip_completed',
]);

const RIDE_STATUS_TO_EVENT = Object.freeze({
  searching: 'ride_requested',
  driver_assigned: 'ride_accepted',
  driver_arrived: 'driver_arrived',
  ride_started: 'trip_started',
  completed: 'trip_completed',
});

function userRoom(userId) {
  return `user_${String(userId || '').trim()}`;
}

function driverRoom(driverId) {
  return `driver_${String(driverId || '').trim()}`;
}

function isDriver(identity) {
  const role = String(identity?.role || identity?.claims?.role || '').toLowerCase();
  return role === 'driver' || identity?.claims?.driver === true;
}

function validIdentity(identity) {
  return identity && typeof identity.uid === 'string' && identity.uid.trim().length > 0;
}

export function createRideSocketNotificationEngine({ io, verifyIdToken, now = () => Date.now() } = {}) {
  if (!io || typeof io.on !== 'function' || typeof io.to !== 'function') {
    throw new Error('A Socket.io server instance is required.');
  }
  if (typeof verifyIdToken !== 'function') {
    throw new Error('A Firebase ID token verifier is required.');
  }

  io.use(async (socket, next) => {
    try {
      const token = String(socket.handshake?.auth?.token || '').trim();
      const identity = await verifyIdToken(token);
      if (!validIdentity(identity)) return next(new Error('SOCKET_UNAUTHORIZED'));
      socket.data.identity = identity;
      return next();
    } catch (_) {
      return next(new Error('SOCKET_UNAUTHORIZED'));
    }
  });

  io.on('connection', (socket) => {
    const identity = socket.data.identity;
    socket.join(userRoom(identity.uid));
    if (isDriver(identity)) socket.join(driverRoom(identity.uid));

    socket.emit('socket_ready', {
      userId: identity.uid,
      driverRoomJoined: isDriver(identity),
      connectedAtMs: now(),
    });
  });

  function emitMilestone({ milestone, rideId, userId, driverId, ride = {} } = {}) {
    if (!RIDE_MILESTONE_EVENTS.includes(milestone)) {
      throw new Error('Unsupported ride milestone event.');
    }
    if (!String(rideId || '').trim() || !String(userId || '').trim()) {
      throw new Error('rideId and userId are required for a ride milestone.');
    }

    const payload = Object.freeze({
      event: milestone,
      rideId: String(rideId).trim(),
      status: milestone,
      occurredAtMs: now(),
      ride: {
        driverId: String(driverId || '').trim(),
        estimatedMinutes: Number(ride.estimatedMinutes || 0),
        estimatedFare: Number(ride.estimatedFare || 0),
        pickupLocation: ride.pickupLocation || null,
        destinationLocation: ride.destinationLocation || null,
      },
    });

    io.to(userRoom(userId)).emit(milestone, payload);
    if (driverId) io.to(driverRoom(driverId)).emit(milestone, payload);
    return payload;
  }

  function emitForRideStatus(ride) {
    const milestone = RIDE_STATUS_TO_EVENT[ride?.status];
    if (!milestone) return null;
    return emitMilestone({
      milestone,
      rideId: ride.rideId,
      userId: ride.userId,
      driverId: ride.driverId,
      ride,
    });
  }

  return Object.freeze({
    emitMilestone,
    emitForRideStatus,
    userRoom,
    driverRoom,
  });
}

export function attachRideStatusListener({ firestore, notificationEngine, logger = console } = {}) {
  if (!firestore || typeof firestore.collection !== 'function') {
    throw new Error('A Firestore instance is required.');
  }
  if (!notificationEngine || typeof notificationEngine.emitForRideStatus !== 'function') {
    throw new Error('A ride socket notification engine is required.');
  }

  const knownStatuses = new Map();
  let initialized = false;
  return firestore.collection('rides').onSnapshot((snapshot) => {
    for (const change of snapshot.docChanges()) {
      const ride = { ...change.doc.data(), rideId: change.doc.id };
      const previousStatus = knownStatuses.get(ride.rideId);

      if (change.type === 'removed') {
        knownStatuses.delete(ride.rideId);
        continue;
      }

      knownStatuses.set(ride.rideId, ride.status);
      if (!initialized || previousStatus === ride.status) continue;

      try {
        notificationEngine.emitForRideStatus(ride);
      } catch (error) {
        logger.error('Ride socket notification failed', error);
      }
    }
    initialized = true;
  }, (error) => logger.error('Ride status listener failed', error));
}