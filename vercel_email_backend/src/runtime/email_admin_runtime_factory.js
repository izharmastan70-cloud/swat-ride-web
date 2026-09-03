/**
 * Email Admin Runtime Factory
 * 
 * Constructs fully-wired email service runtime with Firebase Admin SDK
 * and active provider transport for Phase 44-F3D-C+ deployments.
 * 
 * This replaces the disabled mock implementations with real, authorized
 * service instances for production email delivery.
 */

import {
  getAuth,
  getFirestore,
} from 'firebase-admin/app';

import {
  FirebaseAdminIdTokenVerifier,
} from '../security/firebase_admin_id_token_verifier.js';

import {
  FirebaseAdminSuperAdminAuthorizer,
} from '../security/firebase_admin_super_admin_authorizer.js';

import {
  FirebaseAdminEmailMasterToggleRechecker,
} from '../security/firebase_admin_email_master_toggle_rechecker.js';

import {
  FirebaseAdminConsumedApprovalRechecker,
} from '../security/firebase_admin_consumed_approval_rechecker.js';

import {
  FirebaseAdminVerifiedSenderIdentityVerifier,
} from '../security/firebase_admin_verified_sender_identity_verifier.js';

import {
  FirebaseAdminEmailReplayGuard,
} from '../security/firebase_admin_email_replay_guard.js';

import {
  BrevoTransactionalEmailTransport,
} from '../providers/brevo_transactional_email_transport.js';

/**
 * Factory for production email runtime.
 * 
 * @param {Object} params
 * @param {Object} params.firebaseApp - Firebase Admin app instance
 * @param {string} params.brevoApiKey - Brevo transactional email API key
 * @param {number} params.replayGuardTtlMs - Replay guard TTL in milliseconds
 * @returns {Object} Configured runtime with all security checks enabled
 */
export function createEmailAdminRuntime({
  firebaseApp,
  brevoApiKey,
  replayGuardTtlMs = 3600000, // 1 hour
} = {}) {
  if (!firebaseApp) {
    throw new Error('Firebase app instance is required.');
  }

  if (typeof brevoApiKey !== 'string' || !brevoApiKey.trim()) {
    throw new Error('Brevo API key is required.');
  }

  const auth = getAuth(firebaseApp);
  const firestore = getFirestore(firebaseApp);

  if (!auth || !firestore) {
    throw new Error('Firebase Auth and Firestore must be available.');
  }

  // Create security verification chain
  const authVerifier = new FirebaseAdminIdTokenVerifier({
    auth,
    checkRevoked: true,
  });

  const superAdminAuthorizer = new FirebaseAdminSuperAdminAuthorizer({
    firestore,
  });

  const masterToggleRechecker = new FirebaseAdminEmailMasterToggleRechecker({
    firestore,
  });

  const approvalRechecker = new FirebaseAdminConsumedApprovalRechecker({
    firestore,
  });

  const senderVerifier = new FirebaseAdminVerifiedSenderIdentityVerifier({
    firestore,
  });

  const replayGuard = new FirebaseAdminEmailReplayGuard({
    firestore,
    ttlMs: replayGuardTtlMs,
  });

  // Create provider transport
  const providerTransport = new BrevoTransactionalEmailTransport({
    apiKey: brevoApiKey,
  });

  return Object.freeze({
    authVerifier,
    superAdminAuthorizer,
    masterToggleRechecker,
    approvalRechecker,
    senderVerifier,
    replayGuard,
    providerTransport,
    firebaseApp,
    firestore,
    auth,
    ready: true,
  });
}
