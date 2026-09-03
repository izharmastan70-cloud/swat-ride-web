# Phase 66 Step 1I-T-Q

This directory is an **offline scaffold only** for the future one-time
Security Incident role-inventory migration authority.

## Current locked state

- `executionArmed = false`
- dry-run only
- no Firebase Admin SDK initialization
- no credential loading
- no network read
- no network write
- no Firestore read/write
- no authority-manifest bootstrap
- no migration-hold bootstrap
- no role creation
- no approval consumption
- no guard/token/receipt mutation
- no repository attach/arm
- no incident write
- no SUGGEST_ONLY
- no AUTO

`firebase-admin` is declared in `package.json` only as the future trusted
authority dependency. Step 1I-T-Q does **not** run `npm install`.

The dry-run CLI validates a local evidence JSON file only.

## Future production boundary

A later separately approved step must:

1. install and pin the Admin SDK dependency;
2. establish a trusted credential mechanism without embedding secrets;
3. fresh-read the live `agent_roles` collection from project `swat-ride-v2`;
4. prove exactly 22 unique current roles and absence of
   `security_incident_agent`;
5. recompute the exact authoritative current role projection fingerprint;
6. recompute the proposed 23-role fingerprint;
7. bind the current control fingerprint;
8. verify fresh Owner identity and exact approval binding;
9. verify MONITOR_ONLY and immutable old guard/token/receipt evidence;
10. bootstrap authority manifest + migration hold + audit atomically;
11. keep the later 22->23 role delta as a separate execution boundary.

Admin SDK bypasses Firestore Security Rules, so a future implementation must
apply all exact preconditions in trusted code and preserve immutable audit
evidence.

Do not place service-account JSON, tokens, passwords, or private keys in this
directory.