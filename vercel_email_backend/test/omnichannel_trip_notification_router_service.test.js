import assert from 'node:assert/strict';
import test from 'node:test';
import { dispatchTripNotification } from '../src/services/omnichannel_trip_notification_router_service.js';

test('Super Admin relay pause prevents SMS and WhatsApp delivery attempts', async () => {
  const result = await dispatchTripNotification({
    channel: 'sms',
    callSessionId: 'call-123',
    recipientPhone: '+923001234567',
    messageBody: 'Booking confirmed',
    localRelayEnabled: false,
  });

  assert.deepEqual(result, {
    status: 'PAUSED_BY_SUPER_ADMIN',
    providerMessageId: '',
  });
});

test('in-app confirmations do not depend on the local relay switch', async () => {
  const result = await dispatchTripNotification({
    channel: 'app',
    callSessionId: 'call-123',
    recipientPhone: '+923001234567',
    messageBody: 'Booking confirmed',
    localRelayEnabled: false,
  });

  assert.equal(result.status, 'DELIVERED_VIA_APP_REALTIME_CHANNEL');
});