# SWAT RIDE Email Backend â€” Phase 44-F3D-C

This directory is an isolated Vercel server security skeleton.

## Current state

- Live email send is hard-disabled.
- No Brevo API call exists.
- No Firebase Admin SDK import exists yet.
- No provider secret is read.
- No Firebase service-account value is read.
- No deployment is performed by this phase.
- The Flutter client remains unable to access server secrets.

## Required future execution order

1. Accept POST only.
2. Require an Authorization Bearer token.
3. Parse and validate the immutable Email handoff.
4. Verify Firebase ID token on the trusted server.
5. Re-check the exact consumed approval on the trusted server.
6. Require exact role/action/module/draft fingerprint/handoff scope.
7. Re-check exact verified + enabled sender identity.
8. Require provider ID/from-address match.
9. Check anti-replay/idempotency using approvalId + handoffId.
10. Only after every gate passes may a future provider adapter execute.

## Fail closed

A missing/invalid token, approval mismatch, sender mismatch, replay, disabled
provider, or unavailable trusted dependency must fail closed.

## Secrets

Future Vercel Preview/Production configuration should use sensitive
environment variables for provider/admin credentials.

Reference names:

- BREVO_API_KEY
- FIREBASE_SERVICE_ACCOUNT_JSON
- SWAT_RIDE_FIREBASE_PROJECT_ID

Never put secret values in Flutter, source control, audit metadata, request
payloads, or tests.

## Phase 44-F3D-C transport status

BREVO LIVE SEND: OFF
VERCEL DEPLOY: NOT PERFORMED