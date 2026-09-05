// Concurrency pool for the AI voice agent fleet. Every simultaneous inbound
// call (from a multi-line GSM gateway / SIP trunk) must acquire a "line"
// here before an AI voice agent starts talking to the caller; this is what
// lets multiple calls be routed to distinct virtual agents at once instead
// of dropping or busy-signalling extra callers.
//
// Mirrors the human-agent AgentSeatService pattern (lib/ride_admin/services
// /agent_seat_service.dart) but tracks AI-driven lines server-side, since
// the multi-line gateway itself has no Flutter UI/session.
import { FieldValue, Timestamp } from 'firebase-admin/firestore';

const CAPACITY_DOCUMENT_ID = 'active_line_count';
const DEFAULT_MAX_CONCURRENT_LINES = 5;
const DEFAULT_STALE_LINE_TIMEOUT_MS = 10 * 60 * 1000; // 10 minutes

function seatsCollection(firestore) {
  return firestore.collection('ai_voice_agent_pool_lines');
}

function capacityDocument(firestore) {
  return firestore.collection('ai_voice_agent_pool_capacity').doc(CAPACITY_DOCUMENT_ID);
}

function isStale(lineData, now, staleTimeoutMs) {
  const lastActivityMs = lineData?.lastActivityAt?.toMillis?.() ?? 0;
  return now - lastActivityMs > staleTimeoutMs;
}

export class AiVoiceAgentPoolFullError extends Error {
  constructor() {
    super('AI_VOICE_AGENT_POOL_FULL');
  }
}

/**
 * Attempts to acquire a concurrent voice line for `callSessionId`. Stale
 * lines (no activity within `staleLineTimeoutMs`) are reclaimed first so a
 * crashed/abandoned call never permanently occupies a slot. Throws
 * `AiVoiceAgentPoolFullError` when every configured line is busy.
 */
export async function acquireVoiceLine({
  firestore,
  callSessionId,
  gatewayId,
  maxConcurrentLines = DEFAULT_MAX_CONCURRENT_LINES,
  staleLineTimeoutMs = DEFAULT_STALE_LINE_TIMEOUT_MS,
}) {
  if (!firestore || typeof firestore.runTransaction !== 'function') {
    throw new Error('A Firestore instance is required.');
  }
  if (!callSessionId || typeof callSessionId !== 'string') {
    throw new Error('INVALID_CALL_SESSION_ID');
  }

  return firestore.runTransaction(async (transaction) => {
    const lineReference = seatsCollection(firestore).doc(callSessionId);
    const existingLine = await transaction.get(lineReference);
    if (existingLine.exists) {
      // Already holding a line (e.g. a retried webhook delivery).
      return { alreadyHeld: true, lineId: callSessionId };
    }

    const activeLinesSnapshot = await transaction.get(
      seatsCollection(firestore).where('status', '==', 'active'),
    );
    const now = Date.now();
    const staleLineIds = [];
    let activeCount = 0;
    for (const document of activeLinesSnapshot.docs) {
      if (isStale(document.data(), now, staleLineTimeoutMs)) {
        staleLineIds.push(document.id);
      } else {
        activeCount += 1;
      }
    }
    for (const staleLineId of staleLineIds) {
      transaction.set(
        seatsCollection(firestore).doc(staleLineId),
        { status: 'reclaimed', releasedAt: Timestamp.now() },
        { merge: true },
      );
    }

    if (activeCount >= maxConcurrentLines) {
      throw new AiVoiceAgentPoolFullError();
    }

    const nowTimestamp = Timestamp.now();
    transaction.set(lineReference, {
      callSessionId,
      gatewayId: gatewayId ?? null,
      status: 'active',
      acquiredAt: nowTimestamp,
      lastActivityAt: nowTimestamp,
    });
    transaction.set(
      capacityDocument(firestore),
      { activeLineCount: FieldValue.increment(1 - staleLineIds.length), updatedAt: nowTimestamp },
      { merge: true },
    );
    return { alreadyHeld: false, lineId: callSessionId };
  });
}

/** Refreshes the activity timestamp so a long-running call is not reclaimed. */
export async function sendVoiceLineHeartbeat({ firestore, callSessionId }) {
  await seatsCollection(firestore).doc(callSessionId).set(
    { lastActivityAt: Timestamp.now() },
    { merge: true },
  );
}

/** Releases a voice line so another caller can be routed to that slot. */
export async function releaseVoiceLine({ firestore, callSessionId }) {
  return firestore.runTransaction(async (transaction) => {
    const lineReference = seatsCollection(firestore).doc(callSessionId);
    const line = await transaction.get(lineReference);
    if (!line.exists || line.data()?.status !== 'active') return { released: false };
    transaction.set(
      lineReference,
      { status: 'ended', releasedAt: Timestamp.now() },
      { merge: true },
    );
    transaction.set(
      capacityDocument(firestore),
      { activeLineCount: FieldValue.increment(-1), updatedAt: Timestamp.now() },
      { merge: true },
    );
    return { released: true };
  });
}

export { DEFAULT_MAX_CONCURRENT_LINES, DEFAULT_STALE_LINE_TIMEOUT_MS };
