'use strict';

const ReplayReservationStatus = Object.freeze({
  RESERVED: 'RESERVED',
  DUPLICATE: 'DUPLICATE',
  CONFLICT: 'CONFLICT',
});

async function reserveInboundEvent({
  replayStore,
  eventId,
  payloadHash,
}) {
  if (
    !replayStore ||
    typeof replayStore.reserveIfAbsent !== 'function'
  ) {
    throw new Error(
      'Persistent replayStore.reserveIfAbsent is required.',
    );
  }

  const result = await replayStore.reserveIfAbsent({
    eventId,
    payloadHash,
  });

  if (!result || typeof result !== 'object') {
    throw new Error('Replay store returned an invalid result.');
  }

  if (
    result.status !== ReplayReservationStatus.RESERVED &&
    result.status !== ReplayReservationStatus.DUPLICATE &&
    result.status !== ReplayReservationStatus.CONFLICT
  ) {
    throw new Error('Replay store returned an unknown status.');
  }

  return result;
}

module.exports = {
  ReplayReservationStatus,
  reserveInboundEvent,
};