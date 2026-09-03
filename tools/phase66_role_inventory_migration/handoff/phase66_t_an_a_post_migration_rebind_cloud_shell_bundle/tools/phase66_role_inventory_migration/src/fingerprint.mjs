import { createHash } from 'node:crypto';

import {
  PROPOSED_ROLE_AI_CLASS,
  PROPOSED_ROLE_ENABLED,
  PROPOSED_ROLE_FORBIDDEN_ACTIONS,
  PROPOSED_ROLE_PRIVACY_LEVEL,
  SECURITY_INCIDENT_ACTION_ID,
  SECURITY_INCIDENT_MODULE,
  SECURITY_INCIDENT_ROLE_ID,
} from './contract.mjs';

export function sha256Hex(value) {
  return createHash('sha256').update(value, 'utf8').digest('hex');
}

function sortedUniqueStrings(values) {
  return [...new Set(values.map((value) => String(value).trim()))].sort();
}

export function normalizeRoleProjection(role) {
  return {
    roleId: String(role.roleId ?? '').trim(),
    module: String(role.module ?? '').trim(),
    enabled: role.enabled === true,
    mode: String(role.mode ?? '').trim(),
    allowedActions: sortedUniqueStrings(role.allowedActions ?? []),
    approvalRequiredActions: sortedUniqueStrings(
      role.approvalRequiredActions ?? [],
    ),
    forbiddenActions: sortedUniqueStrings(role.forbiddenActions ?? []),
    aiClass: String(role.aiClass ?? '').trim(),
    privacyLevel: String(role.privacyLevel ?? '').trim(),
  };
}

export function roleInventoryFingerprint(roles) {
  const projections = roles
    .map(normalizeRoleProjection)
    .sort((a, b) => a.roleId.localeCompare(b.roleId));

  return sha256Hex(JSON.stringify(projections));
}

export function proposedRoleProjection() {
  return {
    roleId: SECURITY_INCIDENT_ROLE_ID,
    module: SECURITY_INCIDENT_MODULE,
    enabled: PROPOSED_ROLE_ENABLED,
    mode: 'ASK_FIRST',
    allowedActions: [SECURITY_INCIDENT_ACTION_ID],
    approvalRequiredActions: [SECURITY_INCIDENT_ACTION_ID],
    forbiddenActions: [...PROPOSED_ROLE_FORBIDDEN_ACTIONS],
    aiClass: PROPOSED_ROLE_AI_CLASS,
    privacyLevel: PROPOSED_ROLE_PRIVACY_LEVEL,
  };
}

export function proposedInventoryFingerprint(currentRoles) {
  return roleInventoryFingerprint([
    ...currentRoles,
    proposedRoleProjection(),
  ]);
}