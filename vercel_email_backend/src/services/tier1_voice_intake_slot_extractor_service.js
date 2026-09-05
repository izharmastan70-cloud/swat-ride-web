// Tier 1 - Voice Intake Agent: deterministic, ordered slot-filling for the
// polite/concise conversational flow that collects pickup/dropoff,
// passenger count, vehicle preference, caller name, and phone number.
//
// The caller's phone number is already known from the inbound call event
// (caller ID), so it is not asked again here. This module is intentionally
// provider-neutral: it works today with plain transcript text supplied by
// any speech-to-text front end, and can later be swapped for a real
// LLM-based extractor behind the same function signature without changing
// callers -- consistent with the rest of this codebase's pluggable
// provider pattern (see whatsapp_outbound_message_transport.js).
import { matchVehiclePreference } from './vehicle_inventory_query_service.js';

export const INTAKE_SLOT_ORDER = Object.freeze([
  'callerName',
  'passengerCount',
  'pickupAddress',
  'destinationAddress',
  'vehiclePreference',
]);

const PROMPTS = Object.freeze({
  callerName: 'Welcome to SWAT RIDE. May I have your name, please?',
  passengerCount: 'Thank you. How many passengers will be travelling?',
  pickupAddress: 'What is your pickup location?',
  destinationAddress: 'And where would you like to go?',
  vehiclePreference: null, // built dynamically from the active fleet list
});

function buildVehiclePrompt(activeVehicleInventory) {
  const names = activeVehicleInventory.map((vehicle) => vehicle.name).join(', ');
  return `Which vehicle would you prefer today? We currently have: ${names}.`;
}

function extractPassengerCount(transcript) {
  const digitsMatch = String(transcript ?? '').match(/\d+/);
  const count = digitsMatch ? parseInt(digitsMatch[0], 10) : NaN;
  if (!Number.isInteger(count) || count < 1 || count > 8) return { error: 'INVALID_PASSENGER_COUNT' };
  return { value: count };
}

function extractFreeText(transcript, { maxLength = 160 } = {}) {
  const normalized = String(transcript ?? '').trim();
  if (!normalized || normalized.length > maxLength) return { error: 'INVALID_RESPONSE' };
  return { value: normalized };
}

function extractVehiclePreference(transcript, activeVehicleInventory) {
  const matched = matchVehiclePreference({ inventory: activeVehicleInventory, spokenText: transcript });
  if (!matched) return { error: 'VEHICLE_NOT_AVAILABLE' };
  return { value: matched.vehicleId };
}

function extractSlotValue(slot, transcript, activeVehicleInventory) {
  switch (slot) {
    case 'callerName':
      return extractFreeText(transcript, { maxLength: 80 });
    case 'passengerCount':
      return extractPassengerCount(transcript);
    case 'pickupAddress':
    case 'destinationAddress':
      return extractFreeText(transcript, { maxLength: 200 });
    case 'vehiclePreference':
      return extractVehiclePreference(transcript, activeVehicleInventory);
    default:
      return { error: 'UNKNOWN_SLOT' };
  }
}

function promptFor(slot, activeVehicleInventory) {
  if (slot === 'vehiclePreference') return buildVehiclePrompt(activeVehicleInventory);
  return PROMPTS[slot];
}

/**
 * Advances a single conversational turn. `filledSlots` is the set of slots
 * already collected in this session (plain object keyed by slot name).
 * Returns `{ complete, filledSlots, promptText, missingSlot }`.
 */
export function advanceVoiceIntake({ filledSlots = {}, transcript, activeVehicleInventory = [] }) {
  const currentSlot = INTAKE_SLOT_ORDER.find((slot) => filledSlots[slot] === undefined);

  if (!currentSlot) {
    return { complete: true, filledSlots, promptText: null, missingSlot: null };
  }

  // The first turn only delivers a greeting/prompt; there is no caller
  // answer to parse yet.
  if (transcript === undefined || transcript === null) {
    return {
      complete: false,
      filledSlots,
      promptText: promptFor(currentSlot, activeVehicleInventory),
      missingSlot: currentSlot,
    };
  }

  const { value, error } = extractSlotValue(currentSlot, transcript, activeVehicleInventory);
  if (error) {
    return {
      complete: false,
      filledSlots,
      promptText: `Sorry, I did not catch that. ${promptFor(currentSlot, activeVehicleInventory)}`,
      missingSlot: currentSlot,
      error,
    };
  }

  const updatedSlots = { ...filledSlots, [currentSlot]: value };
  const nextSlot = INTAKE_SLOT_ORDER.find((slot) => updatedSlots[slot] === undefined);
  if (!nextSlot) {
    return { complete: true, filledSlots: updatedSlots, promptText: null, missingSlot: null };
  }
  return {
    complete: false,
    filledSlots: updatedSlots,
    promptText: promptFor(nextSlot, activeVehicleInventory),
    missingSlot: nextSlot,
  };
}
