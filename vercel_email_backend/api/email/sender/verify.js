import {
  handleTrustedBrevoVerificationOnlyRoute,
} from '../../../src/handlers/brevo_verification_only_trusted_route_handler.js';

import {
  disabledBrevoVerificationRouteRuntime,
  disabledIdentityGate,
  disabledSuperAdminGate,
} from '../../../src/runtime/disabled_brevo_verification_route_runtime.js';

export default async function handler(
  request,
  response,
) {
  return handleTrustedBrevoVerificationOnlyRoute({
    request,
    response,
    idTokenVerifier:
        disabledIdentityGate,
    superAdminAuthorizer:
        disabledSuperAdminGate,
    verificationRuntime:
        disabledBrevoVerificationRouteRuntime,
  });
}