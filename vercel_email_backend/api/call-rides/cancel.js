import { cert, getApp, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore } from 'firebase-admin/firestore';

function requiredText(value, name) {
  const result = typeof value === 'string' ? value.trim() : '';
  if (!result || result.length > 240) throw new Error(`INVALID_${name}`);
  return result;
}

function initializeFirebase() {
  try {
    return getApp('swat-ride-call-dispatch');
  } catch (_) {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    const projectId = process.env.SWAT_RIDE_FIREBASE_PROJECT_ID;
    if (!serviceAccountJson || !projectId) throw new Error('FIREBASE_ADMIN_CONFIGURATION_MISSING');
    return initializeApp({ credential: cert(JSON.parse(serviceAccountJson)), projectId }, 'swat-ride-call-dispatch');
  }
}

export default async function handler(request, response) {
  if (request.method !== 'POST') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  try {
    const bearer = request.headers.authorization ?? '';
    const token = bearer.startsWith('Bearer ') ? bearer.substring(7) : '';
    const app = initializeFirebase();
    const auth = getAuth(app);
    const firestore = getFirestore(app);
    const identity = await auth.verifyIdToken(token, true);
    const admin = await firestore.collection('admins').doc(identity.uid).get();
    const data = admin.data() ?? {};
    const role = String(data.role ?? identity.role ?? '').toLowerCase();
    if (!admin.exists || data.isActive !== true || !['admin', 'super_admin'].includes(role)) {
      return response.status(403).json({ ok: false, code: 'CANCELLATION_NOT_AUTHORIZED' });
    }

    const rideId = requiredText(request.body?.rideId, 'RIDE_ID');
    const reason = requiredText(request.body?.reason, 'CANCELLATION_REASON');
    await firestore.runTransaction(async (transaction) => {
      const rideReference = firestore.collection('rides').doc(rideId);
      const ride = await transaction.get(rideReference);
      const rideData = ride.data() ?? {};
      if (!ride.exists || rideData.bookingSource !== 'agent_phone_call') throw new Error('PHONE_CALL_RIDE_NOT_FOUND');
      if (rideData.status === 'cancelled') return;
      if (rideData.status === 'ride_started' || rideData.status === 'completed') throw new Error('RIDE_CANNOT_BE_CANCELLED');
      // Locks cancellation to the agent who booked the call, unless a super admin overrides.
      if (rideData.bookedByAdminId !== identity.uid && role !== 'super_admin') {
        throw new Error('RIDE_LOCKED_TO_ANOTHER_AGENT');
      }
      const driverId = String(rideData.driverId ?? '');
      transaction.update(rideReference, {
        status: 'cancelled',
        cancelledBy: 'agent',
        cancellationReason: reason,
        cancelledAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      if (driverId) {
        const driverReference = firestore.collection('drivers').doc(driverId);
        const driver = await transaction.get(driverReference);
        if (driver.exists && driver.data()?.activeRideId === rideId) {
          transaction.set(driverReference, {
            activeRideId: null,
            isAvailable: driver.data()?.isOnline === true,
            updatedAt: FieldValue.serverTimestamp(),
          }, { merge: true });
        }
      }
    });
    return response.status(200).json({ ok: true, rideId });
  } catch (error) {
    const code = String(error?.message ?? 'CANCELLATION_FAILED');
    const status = code.startsWith('INVALID_')
      ? 400
      : code === 'RIDE_LOCKED_TO_ANOTHER_AGENT'
        ? 403
        : ['PHONE_CALL_RIDE_NOT_FOUND', 'RIDE_CANNOT_BE_CANCELLED'].includes(code)
          ? 409
          : 500;
    return response.status(status).json({ ok: false, code });
  }
}