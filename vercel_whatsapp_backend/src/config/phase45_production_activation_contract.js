'use strict';

const REQUIRED_PRODUCTION_GATES = Object.freeze([
  'providerSelected',
  'serverSecretsConfigured',
  'providerSignatureVerifierConfigured',
  'persistentReplayStoreConfigured',
  'inboundIdempotencyConfigured',
  'webhookRouteConfigured',
  'currentProviderPolicyReviewed',
  'customerConsentPolicyConfigured',
  'outboundTransportConfigured',
  'ownerExplicitActivation',
]);

function evaluateProductionActivation(input = {}) {
  const missing = REQUIRED_PRODUCTION_GATES.filter(
    (key) => input[key] !== true,
  );

  return Object.freeze({
    allowed: missing.length === 0,
    missing: Object.freeze([...missing]),
  });
}

module.exports = {
  REQUIRED_PRODUCTION_GATES,
  evaluateProductionActivation,
};