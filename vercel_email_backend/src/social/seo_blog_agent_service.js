const supportedTopics = new Set(['local_ride_services', 'transport_guide', 'swat_travel']);

function cleanText(value, fallback = '') {
  return typeof value === 'string' ? value.trim() : fallback;
}

function required(value, name) {
  if (!value) throw new Error(`SEO_BLOG_AI_${name}_MISSING`);
  return value;
}

export function createSeoBlogPrompt({ topic, audience = 'local residents and visitors' } = {}) {
  const normalizedTopic = cleanText(topic).toLowerCase();
  if (!supportedTopics.has(normalizedTopic)) throw new Error('SEO_BLOG_TOPIC_UNSUPPORTED');
  return [
    'Return valid JSON only with title, slug, metaDescription, keywords, and bodyMarkdown.',
    'Write an accurate, practical Swat Valley transport article for ' + cleanText(audience, 'local residents and visitors') + '.',
    'Focus on ' + normalizedTopic.replaceAll('_', ' ') + '.',
    'Do not invent fares, availability, routes, safety guarantees, or local regulations. Use neutral, helpful language.',
    'metaDescription must be 150-160 characters. keywords must be 5-10 specific, non-duplicated strings.',
  ].join('\n');
}

function parseDraft(body) {
  const content = body.choices?.[0]?.message?.content;
  let draft;
  try { draft = JSON.parse(content); } catch (_) { throw new Error('SEO_BLOG_AI_RESPONSE_INVALID'); }
  if (!cleanText(draft.title) || !cleanText(draft.slug) || !cleanText(draft.metaDescription) || !Array.isArray(draft.keywords) || !cleanText(draft.bodyMarkdown)) {
    throw new Error('SEO_BLOG_AI_RESPONSE_INVALID');
  }
  return {
    title: cleanText(draft.title),
    slug: cleanText(draft.slug).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, ''),
    metaDescription: cleanText(draft.metaDescription),
    keywords: draft.keywords.map((value) => cleanText(value)).filter(Boolean).slice(0, 10),
    bodyMarkdown: cleanText(draft.bodyMarkdown),
  };
}

export async function generateSeoBlogDraft({ topic, audience, environment = process.env, fetchFn = fetch } = {}) {
  const endpoint = required(environment.SEO_BLOG_AI_ENDPOINT, 'ENDPOINT');
  const apiKey = required(environment.SEO_BLOG_AI_API_KEY, 'API_KEY');
  const model = required(environment.SEO_BLOG_AI_MODEL, 'MODEL');
  const response = await fetchFn(endpoint, {
    method: 'POST',
    headers: { authorization: `Bearer ${apiKey}`, 'content-type': 'application/json' },
    body: JSON.stringify({ model, response_format: { type: 'json_object' }, messages: [{ role: 'user', content: createSeoBlogPrompt({ topic, audience }) }] }),
  });
  const body = await response.json().catch(() => ({}));
  if (!response.ok) throw new Error('SEO_BLOG_AI_REQUEST_REJECTED');
  return parseDraft(body);
}