import { timingSafeEqual } from 'node:crypto';
import { discoverBillingServices, findExpiryAlerts, formatExpiryAlert, markExpiryAlertSent, scanForBillingSubscriptions } from '../../src/services/billing_subscription_alert_agent_service.js';
import { dispatchTripNotification } from '../../src/services/omnichannel_trip_notification_router_service.js';
import { firestore } from '../calls/_shared.js';

function authorized(request) {
  const expected = process.env.CRON_SECRET;
  const received = String(request.headers.authorization ?? '').replace(/^Bearer\s+/i, '');
  if (!expected || !received) return false;
  const expectedBuffer = Buffer.from(expected);
  const receivedBuffer = Buffer.from(received);
  return expectedBuffer.length === receivedBuffer.length && timingSafeEqual(expectedBuffer, receivedBuffer);
}

export default async function handler(request, response) {
  if (request.method !== 'GET') return response.status(405).json({ ok: false, code: 'METHOD_NOT_ALLOWED' });
  if (!authorized(request)) return response.status(401).json({ ok: false, code: 'CRON_NOT_AUTHORIZED' });
  try {
    const firestoreInstance = firestore();
    const controls = await firestoreInstance.collection('app_config').doc('super_admin_operational_controls').get();
    const controlData = controls.data() ?? {};
    const scan = controlData.billingAutoDiscoveryEnabled === false
      ? { discoveries: discoverBillingServices({}), scanId: null, skipped: true }
      : await scanForBillingSubscriptions({ firestore: firestoreInstance });
    const alerts = controlData.billingWhatsAppAlertsEnabled === false
      ? []
      : await findExpiryAlerts({ firestore: firestoreInstance });
    const recipientPhone = process.env.SUPER_ADMIN_ALERT_PHONE;
    const relayEnabled = controlData.localMessagingRelayEnabled !== false;
    let sentAlerts = 0;
    for (const alert of alerts) {
      if (!recipientPhone) break;
      const result = await dispatchTripNotification({
        channel: 'whatsapp',
        callSessionId: `billing:${alert.subscriptionId}:${alert.alertType}`,
        recipientPhone,
        messageBody: formatExpiryAlert(alert),
        localRelayEnabled: relayEnabled,
      });
      if (result.status === 'ACCEPTED') {
        await markExpiryAlertSent({ firestore: firestoreInstance, subscriptionId: alert.subscriptionId, alertType: alert.alertType });
        sentAlerts += 1;
      }
    }
    return response.status(200).json({ ok: true, scanId: scan.scanId, discovered: scan.discoveries.length, sentAlerts });
  } catch (error) {
    console.error('Billing subscription daily job failed.', { code: String(error?.message ?? 'BILLING_JOB_FAILED') });
    return response.status(500).json({ ok: false, code: 'BILLING_JOB_FAILED' });
  }
}