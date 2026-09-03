export function extractBearerToken(request) {
  const header = request.headers.get('authorization') ?? '';
  const match = /^Bearer\s+(.+)$/i.exec(header.trim());

  if (!match || !match[1].trim()) {
    return '';
  }

  return match[1].trim();
}