'use strict';

const crypto = require('node:crypto');

function isAuthenticatedRelayRequest({ providedSecret, expectedSecret }) {
  if (typeof providedSecret !== 'string' ||
      typeof expectedSecret !== 'string' ||
      expectedSecret.length < 32) {
    return false;
  }

  const provided = Buffer.from(providedSecret, 'utf8');
  const expected = Buffer.from(expectedSecret, 'utf8');
  return provided.length === expected.length &&
      crypto.timingSafeEqual(provided, expected);
}

module.exports = { isAuthenticatedRelayRequest };