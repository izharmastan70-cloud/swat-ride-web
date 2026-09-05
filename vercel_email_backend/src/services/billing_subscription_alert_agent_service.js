import { createHash } from 'node:crypto';
import { FieldValue, Timestamp } from 'firebase-admin/firestore';

const SERVICE_PATTERNS = Object.freeze([
  { id: 'firebase', label: 'Firebase / Google Cloud', pattern: /^(FIREBASE|GOOGLE_|SWAT_RIDE_FIREBASE)/ },
  { id: 'maps', label: 'Maps and Routing', pattern: /(MAPS|GOOGLE_MAPS|GEOCODING|OSRM)/ },
  { id: 'payment', label: 'Payment Gateway', pattern: /(JAZZCASH|EASYPAISA|STRIPE|PAYMENT)/ },
  { id: 'whatsapp_sms', label: 'WhatsApp / SMS Gateway', pattern: /(WHATSAPP|TWILIO|SMS|RELAY)/ },
  { id: 'ai', label: 'AI Service', pattern: /(OPENAI|ANTHROPIC|GEMINI|AI_ENDPOINT|AI_MODEL)/ },
  { id: 'pbx', label: 'Cloud PBX / SIP', pattern: /(PBX|SIP|VOICE|GSM_GATEWAY)/ },
  { id: 'vps', label: 'VPS / Hosting', pattern: /(VPS|VERCEL|HOSTING|SERVER_URL)/ },
]);

const SUBSCRIPTIONS_COLLECTION = 'billing_subscriptions';
const SCANS_COLLECTION = 'billing_agent_scans';

function discoveryKey(serviceId, variableNames) {
  return createHash('sha256')
    .update(`${serviceId}:${variableNames.sort().join(',')}`)
    .digest('hex')
    .slice(0, 32);
}

function environmentVariableNames(environment) {
  return Object.keys(environment ?? {}).filter((key) => {
    const value = environment[key];
    return typeof value === 'string' && value.trim().length > 0;
  });
}

export function discoverBillingServices({ environment = process.env }) {
  const names = environmentVariableNames(environment);
  return SERVICE_PATTERNS.map((service) => {
    const variableNames = names.filter((name) => service.pattern.test(name));
    if (!variableNames.length) return null;
    return {
      subscriptionId: discoveryKey(service.id, variableNames),
      serviceId: service.id,
      serviceName: service.label,
      detectedEnvironmentVariables: variableNames.sort(),
    };
  }).filter(Boolean);
}

export async function scanForBillingSubscriptions({ firestore, environment = process.env }) {
  const discoveries = discoverBillingServices({ environment });
  const now = Timestamp.now();
  const batch = firestore.batch();
  for (const discovery of discoveries) {
    const reference = firestore.collection(SUBSCRIPTIONS_COLLECTION).doc(discovery.subscriptionId);
    batch.set(reference, {
      ...discovery,
      source: 'auto_discovery',
      status: 'pending_review',
      estimatedMonthlyCost: null,
      renewalDate: null,
      lastDetectedAt: now,
      updatedAt: now,
    }, { merge: true });
  }
  const scanReference = firestore.collection(SCANS_COLLECTION).doc();
  batch.set(scanReference, {
    status: 'completed',
    discoveredServiceCount: discoveries.length,
    detectedSubscriptionIds: discoveries.map((item) => item.subscriptionId),
    scannedAt: now,
  });
  await batch.commit();
  return { discoveries, scanId: scanReference.id };
}

function daysUntil(date, nowMs) {
  return Math.ceil((date.toMillis() - nowMs) / (24 * 60 * 60 * 1000));
}

export async function findExpiryAlerts({ firestore, nowMs = Date.now() }) {
  const snapshot = await firestore.collection(SUBSCRIPTIONS_COLLECTION)
    .where('status', '==', 'active')
    .get();
  const alerts = [];
  for (const document of snapshot.docs) {
    const data = document.data() ?? {};
    if (!data.renewalDate?.toMillis) continue;
    const days = daysUntil(data.renewalDate, nowMs);
    const alertType = days === 8 ? 'warning_8_days' : days >= 2 && days <= 3 ? 'critical_2_to_3_days' : null;
    if (alertType && data.lastExpiryAlertType !== alertType) {
      alerts.push({ subscriptionId: document.id, serviceName: String(data.serviceName ?? 'Service'), days, alertType });
    }
  }
  return alerts;
}

export async function markExpiryAlertSent({ firestore, subscriptionId, alertType }) {
  await firestore.collection(SUBSCRIPTIONS_COLLECTION).doc(subscriptionId).set({
    lastExpiryAlertType: alertType,
    lastExpiryAlertAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
}

export function formatExpiryAlert({ serviceName, days, alertType }) {
  const severity = alertType === 'warning_8_days' ? 'WARNING' : 'CRITICAL';
  return `SWAT RIDE billing ${severity}: ${serviceName} renews or expires in ${days} day(s). Review Billing & Subscriptions in Super Admin.`;
}