export const EMAIL_SENDER_VERIFICATION_OPERATION =
    'email.sender.verify.read_only';

export const EMAIL_SENDER_VERIFICATION_ROUTE_POLICY =
    Object.freeze({
      allowedMethod:
          'POST',
      requiresBearerToken:
          true,
      requiresVerifiedFirebaseIdentity:
          true,
      requiresSuperAdmin:
          true,
      providerReadAllowedOnlyAfterAllGates:
          true,
      providerWriteAllowed:
          false,
      firestoreWriteAllowed:
          false,
      emailSendAllowed:
          false,
      liveSendAllowed:
          false,
      mayConsumeEmailApproval:
          false,
      mayClaimDeliveryIdempotency:
          false,
      cacheable:
          false,

      // IMPORTANT:
      // This route is verification-only. It is completely separate from
      // api/email/send.js and cannot send transactional email.
      //
      // The provider verification runtime passed to this handler must remain
      // disabled until a later owner-controlled activation step.
      //
      // Live Email Agent activation is still blocked until the draft binding
      // is migrated from CANONICAL_JSON_SHA256_BASE64URL_V2 to a cryptographic
      // SHA-256 canonical digest with explicit algorithm/version tests.
      sha256DraftBindingRequiredBeforeLiveSend:
          true,
    });

function safeJson(
  response,
  statusCode,
  body,
) {
  if (!response ||
      typeof response.status !== 'function' ||
      typeof response.json !== 'function') {
    throw new Error(
        'Verification-only response adapter is invalid.');
  }

  if (typeof response.setHeader === 'function') {
    response.setHeader(
        'Cache-Control',
        'no-store, max-age=0');

    response.setHeader(
        'Content-Type',
        'application/json; charset=utf-8');
  }

  return response
      .status(statusCode)
      .json(body);
}

function fail(
  response,
  statusCode,
  code,
) {
  return safeJson(
      response,
      statusCode,
      Object.freeze({
        ok:
            false,
        operation:
            EMAIL_SENDER_VERIFICATION_OPERATION,
        code,
        providerReadPerformed:
            false,
        providerWriteAllowed:
            false,
        firestoreWriteAllowed:
            false,
        emailSendAllowed:
            false,
        liveSendAllowed:
            false,
      }));
}

function readBearerToken(request) {
  const raw =
      request?.headers?.authorization ??
      request?.headers?.Authorization ??
      '';

  if (typeof raw !== 'string') {
    return null;
  }

  const match =
      raw.match(/^Bearer\s+(.+)$/i);

  const token =
      match?.[1]?.trim();

  return token && token.length > 0
      ? token
      : null;
}

export async function handleTrustedBrevoVerificationOnlyRoute({
  request,
  response,
  idTokenVerifier,
  superAdminAuthorizer,
  verificationRuntime,
}) {
  const method =
      typeof request?.method === 'string'
          ? request.method.toUpperCase()
          : '';

  if (method !==
      EMAIL_SENDER_VERIFICATION_ROUTE_POLICY.allowedMethod) {
    if (typeof response?.setHeader === 'function') {
      response.setHeader(
          'Allow',
          EMAIL_SENDER_VERIFICATION_ROUTE_POLICY.allowedMethod);
    }

    return fail(
        response,
        405,
        'EMAIL_SENDER_VERIFICATION_METHOD_NOT_ALLOWED');
  }

  const bearerToken =
      readBearerToken(
          request);

  if (!bearerToken) {
    return fail(
        response,
        401,
        'EMAIL_SENDER_VERIFICATION_BEARER_REQUIRED');
  }

  if (!idTokenVerifier ||
      typeof idTokenVerifier.verify !== 'function') {
    return fail(
        response,
        503,
        'EMAIL_SENDER_VERIFICATION_IDENTITY_GATE_NOT_READY');
  }

  let identity;

  try {
    identity =
        await idTokenVerifier.verify(
            bearerToken);
  } catch (_) {
    return fail(
        response,
        401,
        'EMAIL_SENDER_VERIFICATION_IDENTITY_REJECTED');
  }

  if (!identity ||
      typeof identity.uid !== 'string' ||
      identity.uid.trim().length === 0) {
    return fail(
        response,
        401,
        'EMAIL_SENDER_VERIFICATION_IDENTITY_REJECTED');
  }

  if (!superAdminAuthorizer ||
      typeof superAdminAuthorizer.authorize !== 'function') {
    return fail(
        response,
        503,
        'EMAIL_SENDER_VERIFICATION_SUPER_ADMIN_GATE_NOT_READY');
  }

  let authorized;

  try {
    authorized =
        await superAdminAuthorizer.authorize(
            identity);
  } catch (_) {
    return fail(
        response,
        403,
        'EMAIL_SENDER_VERIFICATION_SUPER_ADMIN_REQUIRED');
  }

  if (authorized !== true) {
    return fail(
        response,
        403,
        'EMAIL_SENDER_VERIFICATION_SUPER_ADMIN_REQUIRED');
  }

  if (!verificationRuntime ||
      typeof verificationRuntime.runVerificationOnly !== 'function') {
    return fail(
        response,
        503,
        'EMAIL_SENDER_VERIFICATION_RUNTIME_NOT_READY');
  }

  const result =
      await verificationRuntime.runVerificationOnly();

  if (!result ||
      typeof result !== 'object') {
    return fail(
        response,
        503,
        'EMAIL_SENDER_VERIFICATION_RUNTIME_INVALID');
  }

  const statusCode =
      result.ok === true
          ? 200
          : result.code ===
                'BREVO_VERIFICATION_ONLY_SERVER_DISABLED'
              ? 503
              : 409;

  return safeJson(
      response,
      statusCode,
      Object.freeze({
        ok:
            result.ok === true,
        operation:
            EMAIL_SENDER_VERIFICATION_OPERATION,
        code:
            result.code ??
            'EMAIL_SENDER_VERIFICATION_RESULT_UNKNOWN',
        trustedEvidenceEligible:
            result.trustedEvidenceEligible === true,
        evidence:
            result.ok === true
                ? result.evidence ?? null
                : null,
        providerReadPerformed:
            result.providerReadPerformed === true,
        providerWriteAllowed:
            false,
        firestoreWriteAllowed:
            false,
        emailSendAllowed:
            false,
        liveSendAllowed:
            false,
      }));
}