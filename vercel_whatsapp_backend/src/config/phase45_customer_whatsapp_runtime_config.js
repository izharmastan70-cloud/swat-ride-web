'use strict';

const PHASE45_CUSTOMER_WHATSAPP_RUNTIME = Object.freeze({
  providerName: '',
  providerId: '',
  providerSelected: false,
  inboundNetworkEnabled: false,
  outboundNetworkEnabled: false,
  webhookRouteEnabled: false,
  liveSendEnabled: false,
  businessExecutionEnabled: false,
  aiBridgeEnabled: false,
  deployNow: false,
});

function buildRuntimeConfig(overrides = {}) {
  const source = { ...PHASE45_CUSTOMER_WHATSAPP_RUNTIME, ...overrides };

  if (source.providerSelected !== true) {
    return Object.freeze({
      ...source,
      providerId: '',
      providerName: '',
      providerSelected: false,
      inboundNetworkEnabled: false,
      outboundNetworkEnabled: false,
      webhookRouteEnabled: false,
      liveSendEnabled: false,
      businessExecutionEnabled: false,
      aiBridgeEnabled: false,
      deployNow: false,
    });
  }

  return Object.freeze({
    ...source,
    providerId: String(source.providerId || '').trim(),
    providerName: String(source.providerName || '').trim(),
    providerSelected: true,
    inboundNetworkEnabled: Boolean(source.inboundNetworkEnabled),
    outboundNetworkEnabled: Boolean(source.outboundNetworkEnabled),
    webhookRouteEnabled: Boolean(source.webhookRouteEnabled),
    liveSendEnabled: Boolean(source.liveSendEnabled),
    businessExecutionEnabled: Boolean(source.businessExecutionEnabled),
    aiBridgeEnabled: Boolean(source.aiBridgeEnabled),
    deployNow: Boolean(source.deployNow),
  });
}

function createRuntimeFromEnvironment(env = process.env) {
  const providerSelected = String(env.CUSTOMER_WHATSAPP_PROVIDER_SELECTED || '').toLowerCase() === 'true';
  const providerName = String(env.CUSTOMER_WHATSAPP_PROVIDER_NAME || '').trim();
  const providerId = String(env.CUSTOMER_WHATSAPP_PROVIDER_ID || '').trim();

  return buildRuntimeConfig({
    providerName,
    providerId,
    providerSelected,
    inboundNetworkEnabled: String(env.CUSTOMER_WHATSAPP_INBOUND_ENABLED || '').toLowerCase() === 'true',
    outboundNetworkEnabled: String(env.CUSTOMER_WHATSAPP_OUTBOUND_ENABLED || '').toLowerCase() === 'true',
    webhookRouteEnabled: String(env.CUSTOMER_WHATSAPP_WEBHOOK_ROUTE_ENABLED || '').toLowerCase() === 'true',
    liveSendEnabled: String(env.CUSTOMER_WHATSAPP_LIVE_SEND_ENABLED || '').toLowerCase() === 'true',
    businessExecutionEnabled: String(env.CUSTOMER_WHATSAPP_BUSINESS_EXECUTION_ENABLED || '').toLowerCase() === 'true',
    aiBridgeEnabled: String(env.CUSTOMER_WHATSAPP_AI_BRIDGE_ENABLED || '').toLowerCase() === 'true',
    deployNow: String(env.CUSTOMER_WHATSAPP_DEPLOY_NOW || '').toLowerCase() === 'true',
  });
}

function assertSafeDefaultRuntime(config = PHASE45_CUSTOMER_WHATSAPP_RUNTIME) {
  if (config.providerSelected) {
    throw new Error('Phase 45 safe default must not preselect a provider.');
  }

  if (String(config.providerId || '').trim() !== '') {
    throw new Error('Phase 45 safe default providerId must be empty.');
  }

  const forbiddenEnabled = [
    config.aiBridgeEnabled,
    config.inboundNetworkEnabled,
    config.outboundNetworkEnabled,
    config.webhookRouteEnabled,
    config.liveSendEnabled,
    config.businessExecutionEnabled,
    config.deployNow,
  ];

  if (forbiddenEnabled.some(Boolean)) {
    throw new Error('Phase 45 safe default runtime must remain fully disabled.');
  }

  return true;
}

module.exports = {
  buildRuntimeConfig,
  createRuntimeFromEnvironment,
  PHASE45_CUSTOMER_WHATSAPP_RUNTIME,
  assertSafeDefaultRuntime,
};