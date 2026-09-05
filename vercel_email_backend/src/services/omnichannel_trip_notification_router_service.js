// Routes trip confirmations back through the exact channel the caller used
// to contact SWAT RIDE:
//   - "app"      : the rider is a real signed-in app user. No extra network
//                  call is needed here -- writing the ride document with the
//                  rider's real Firebase uid as `userId` is already picked
//                  up in real time by the existing Socket.io ride
//                  notification engine (attachRideStatusListener).
//   - "whatsapp" : delivered via the existing local message relay
//                  (PASSENGER_WHATSAPP_RELAY_URL), which forwards to the
//                  local SIM/WhatsApp gateway device.
//   - "sms"      : delivered via the SAME local message relay, using
//                  channel: 'sms' so the local gateway sends a standard SMS
//                  instead of a WhatsApp message.
export const NOTIFICATION_CHANNELS = Object.freeze({
  APP: 'app',
  WHATSAPP: 'whatsapp',
  SMS: 'sms',
});

function normalizeChannel(channel) {
  const value = String(channel ?? '').toLowerCase();
  return Object.values(NOTIFICATION_CHANNELS).includes(value)
    ? value
    : NOTIFICATION_CHANNELS.SMS;
}

/** Builds the standard app-style trip confirmation text used across channels. */
export function formatTripConfirmationMessage({
  driverName,
  driverPhone,
  vehicleName,
  vehicleNumber,
  pickupAddress,
  destinationAddress,
  distanceKm,
  estimatedMinutes,
  estimatedFare,
}) {
  return (
    `SWAT RIDE booking confirmed.\n` +
    `Route: ${pickupAddress} -> ${destinationAddress}\n` +
    `Distance: ${Number(distanceKm).toFixed(1)} km | ETA: ${estimatedMinutes} min\n` +
    `Fare: Rs. ${Number(estimatedFare).toFixed(0)}\n` +
    `Driver: ${driverName} (${vehicleName}${vehicleNumber ? ' - ' + vehicleNumber : ''})\n` +
    `Driver phone: ${driverPhone}`
  );
}

async function sendViaLocalRelay({ recipientPhone, messageBody, callSessionId, channel }) {
  const relayUrl = process.env.PASSENGER_WHATSAPP_RELAY_URL;
  const relayToken = process.env.PASSENGER_WHATSAPP_RELAY_TOKEN;
  if (!relayUrl || !relayToken) {
    return { status: 'NOT_CONFIGURED', providerMessageId: '' };
  }
  const response = await fetch(relayUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-Relay-Secret': relayToken,
    },
    body: JSON.stringify({
      callSessionId,
      recipientPhone,
      messageBody,
      channel,
    }),
  });
  const payload = await response.json().catch(() => ({}));
  if (!response.ok || payload.ok === false) {
    throw new Error('PASSENGER_MESSAGE_RELAY_REJECTED');
  }
  return { status: 'ACCEPTED', providerMessageId: String(payload.messageId ?? '') };
}

/**
 * Delivers a trip notification through the channel the customer originally
 * used to contact SWAT RIDE. Never throws -- delivery failures are reported
 * back as a `FAILED` status so booking flows are never blocked by a
 * notification error.
 */
export async function dispatchTripNotification({
  channel,
  callSessionId,
  recipientPhone,
  messageBody,
  localRelayEnabled = true,
}) {
  const normalizedChannel = normalizeChannel(channel);
  if (normalizedChannel === NOTIFICATION_CHANNELS.APP) {
    return { status: 'DELIVERED_VIA_APP_REALTIME_CHANNEL', providerMessageId: '' };
  }
  if (!localRelayEnabled) {
    return { status: 'PAUSED_BY_SUPER_ADMIN', providerMessageId: '' };
  }
  try {
    return await sendViaLocalRelay({
      recipientPhone,
      messageBody,
      callSessionId,
      channel: normalizedChannel,
    });
  } catch (_) {
    return { status: 'FAILED', providerMessageId: '' };
  }
}
