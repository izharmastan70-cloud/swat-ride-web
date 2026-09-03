import { cert, getApp, initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { FirebaseAdminSuperAdminAuthorizer } from '../security/firebase_admin_super_admin_authorizer.js';
import { createFacebookGraphAdapter } from './facebook_graph_adapter.js';
import { createInstagramGraphAdapter } from './instagram_graph_adapter.js';
import { createTikTokContentPostingAdapter } from './tiktok_content_posting_adapter.js';
import { createYouTubeDataApiAdapter } from './youtube_data_api_adapter.js';

function app() {
  try { return getApp('swat-ride-social'); } catch (_) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON || '');
    return initializeApp({ credential: cert(serviceAccount), projectId: process.env.SWAT_RIDE_FIREBASE_PROJECT_ID }, 'swat-ride-social');
  }
}

export function socialRuntime() {
  const firebaseApp = app();
  const firestore = getFirestore(firebaseApp);
  const auth = getAuth(firebaseApp);
  const superAdmin = new FirebaseAdminSuperAdminAuthorizer({ firestore });
  return {
    firestore,
    async identity(request) {
      const authorization = String(request.headers.authorization || '');
      const token = authorization.startsWith('Bearer ') ? authorization.slice(7) : '';
      return auth.verifyIdToken(token, true);
    },
    async authorizeSuperAdmin(identityOrUid) {
      const identity = typeof identityOrUid === 'object'
        ? identityOrUid
        : { uid: identityOrUid };
      return superAdmin.authorize({
        uid: identity.uid,
        claims: {
          role: identity.role,
          superAdmin: identity.superAdmin === true,
        },
      });
    },
    providers: {
      facebook: createFacebookGraphAdapter({ pageId: process.env.FACEBOOK_PAGE_ID, accessToken: process.env.FACEBOOK_PAGE_ACCESS_TOKEN }),
      instagram: createInstagramGraphAdapter({
        instagramAccountId: process.env.INSTAGRAM_BUSINESS_ACCOUNT_ID,
        pageId: process.env.FACEBOOK_PAGE_ID,
        accessToken: process.env.FACEBOOK_PAGE_ACCESS_TOKEN,
      }),
      tiktok: createTikTokContentPostingAdapter({ accessToken: process.env.TIKTOK_ACCESS_TOKEN }),
      youtube: createYouTubeDataApiAdapter({ accessToken: process.env.YOUTUBE_ACCESS_TOKEN }),
    },
  };
}

export function routeError(response, error) {
  const code = String(error?.message || 'SOCIAL_REQUEST_FAILED');
  const status = code.includes('NOT_SUPER_ADMIN') ? 403 : code.includes('INVALID') || code.includes('UNSUPPORTED') ? 400 : code.includes('NOT_FOUND') ? 404 : code.includes('APPROVAL_REQUIRED') ? 409 : 500;
  return response.status(status).json({ ok: false, code });
}