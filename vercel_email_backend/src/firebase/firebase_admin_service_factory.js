import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

export function createFirebaseAdminServiceHandles(app) {
  if (!app) {
    throw new Error(
        'An already-initialized Firebase Admin app is required.');
  }

  return Object.freeze({
    auth: getAuth(app),
    firestore: getFirestore(app),
  });
}