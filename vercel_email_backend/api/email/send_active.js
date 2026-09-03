/**
 * Active Email Send Handler
 * 
 * Vercel function for Phase 44+ email delivery with full security checks.
 * Uses Firebase Admin SDK with real provider transport (Brevo).
 * 
 * Environment variables required:
 * - FIREBASE_SERVICE_ACCOUNT_JSON
 * - SWAT_RIDE_FIREBASE_PROJECT_ID
 * - BREVO_API_KEY
 */

import {
  initializeApp,
  cert,
  getApp,
} from 'firebase-admin/app';

import { buildPhase44F3dcServerConfig } from '../../src/config/email_server_config.js';
import { createEmailSendHandler } from '../../src/core/email_send_handler.js';
import { createEmailAdminRuntime } from '../../src/runtime/email_admin_runtime_factory.js';
import { BrevoTransactionalEmailTransport } from '../../src/providers/active_brevo_transactional_email_transport.js';

let emailHandlerInstance = null;

/**
 * Initialize email handler with Firebase Admin and Brevo
 */
function initializeEmailHandler() {
  if (emailHandlerInstance) {
    return emailHandlerInstance;
  }

  // Get or create Firebase app
  let firebaseApp;
  try {
    firebaseApp = getApp('swat-ride-email-server');
  } catch (_) {
    const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
    const projectId = process.env.SWAT_RIDE_FIREBASE_PROJECT_ID;

    if (!serviceAccountJson) {
      throw new Error(
        'FIREBASE_SERVICE_ACCOUNT_JSON environment variable is required.'
      );
    }

    if (!projectId) {
      throw new Error(
        'SWAT_RIDE_FIREBASE_PROJECT_ID environment variable is required.'
      );
    }

    let serviceAccount;
    try {
      serviceAccount = JSON.parse(serviceAccountJson);
    } catch (_) {
      throw new Error(
        'FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON.'
      );
    }

    firebaseApp = initializeApp(
      {
        credential: cert(serviceAccount),
        projectId,
      },
      'swat-ride-email-server'
    );
  }

  // Get Brevo API key
  const brevoApiKey = process.env.BREVO_API_KEY;
  if (!brevoApiKey) {
    throw new Error('BREVO_API_KEY environment variable is required.');
  }

  // Create runtime with Firebase Admin and Brevo
  const runtime = createEmailAdminRuntime({
    firebaseApp,
    brevoApiKey,
  });

  // Create email send handler
  const config = buildPhase44F3dcServerConfig();

  emailHandlerInstance = createEmailSendHandler({
    config,
    authVerifier: runtime.authVerifier,
    superAdminAuthorizer: runtime.superAdminAuthorizer,
    masterToggleRechecker: runtime.masterToggleRechecker,
    approvalRechecker: runtime.approvalRechecker,
    senderVerifier: runtime.senderVerifier,
    replayGuard: runtime.replayGuard,
    providerTransport: runtime.providerTransport,
  });

  return emailHandlerInstance;
}

/**
 * Vercel Edge Runtime handler
 */
export default {
  async fetch(request) {
    try {
      const handler = initializeEmailHandler();
      return handler(request);
    } catch (error) {
      console.error('Email handler initialization failed:', error);
      return Response.json(
        {
          ok: false,
          code: 'HANDLER_INITIALIZATION_FAILED',
          reason: error?.message || 'Unknown error',
        },
        { status: 503 }
      );
    }
  },
};
