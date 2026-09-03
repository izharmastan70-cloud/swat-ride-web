import {
  cert,
  getApp,
  initializeApp,
} from 'firebase-admin/app';

export const EMAIL_FIREBASE_ADMIN_APP_NAME =
    'swat-ride-email-server';

function nonEmptyString(value) {
  return typeof value === 'string' && value.trim().length > 0;
}

function parseServiceAccountJson(serviceAccountJson) {
  if (!nonEmptyString(serviceAccountJson)) {
    throw new Error(
        'FIREBASE_SERVICE_ACCOUNT_JSON is missing.');
  }

  let parsed;

  try {
    parsed = JSON.parse(serviceAccountJson);
  } catch (_) {
    throw new Error(
        'FIREBASE_SERVICE_ACCOUNT_JSON is not valid JSON.');
  }

  const projectId =
      String(
          parsed.project_id ??
          parsed.projectId ??
          '').trim();

  const clientEmail =
      String(
          parsed.client_email ??
          parsed.clientEmail ??
          '').trim();

  const privateKey =
      String(
          parsed.private_key ??
          parsed.privateKey ??
          '').replace(/\\n/g, '\n').trim();

  if (!projectId || !clientEmail || !privateKey) {
    throw new Error(
        'Firebase service account is missing project/client/private-key fields.');
  }

  return Object.freeze({
    projectId,
    clientEmail,
    privateKey,
  });
}

export function createFirebaseAdminAppInitializer({
  getAppFn = getApp,
  initializeAppFn = initializeApp,
  certFn = cert,
  appName = EMAIL_FIREBASE_ADMIN_APP_NAME,
} = {}) {
  return function initializeEmailFirebaseAdminApp({
    serviceAccountJson,
    expectedProjectId,
  }) {
    const normalizedExpectedProjectId =
        String(expectedProjectId ?? '').trim();

    if (!normalizedExpectedProjectId) {
      throw new Error(
          'SWAT_RIDE_FIREBASE_PROJECT_ID is missing.');
    }

    let existingApp = null;

    try {
      existingApp = getAppFn(appName);
    } catch (_) {
      existingApp = null;
    }

    if (existingApp) {
      return Object.freeze({
        app: existingApp,
        initializedNow: false,
        appName,
        projectId: normalizedExpectedProjectId,
      });
    }

    const serviceAccount =
        parseServiceAccountJson(serviceAccountJson);

    if (serviceAccount.projectId !== normalizedExpectedProjectId) {
      throw new Error(
          'Firebase service-account project does not match configured project.');
    }

    const credential =
        certFn({
          projectId: serviceAccount.projectId,
          clientEmail: serviceAccount.clientEmail,
          privateKey: serviceAccount.privateKey,
        });

    const app =
        initializeAppFn(
            {
              credential,
              projectId:
                  normalizedExpectedProjectId,
            },
            appName);

    return Object.freeze({
      app,
      initializedNow: true,
      appName,
      projectId: normalizedExpectedProjectId,
    });
  };
}