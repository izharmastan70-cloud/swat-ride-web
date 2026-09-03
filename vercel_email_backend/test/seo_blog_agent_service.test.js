import assert from 'node:assert/strict';
import test from 'node:test';
import { createSeoBlogPrompt, generateSeoBlogDraft } from '../src/social/seo_blog_agent_service.js';

const environment = { SEO_BLOG_AI_ENDPOINT: 'https://ai.example.com/v1/chat/completions', SEO_BLOG_AI_API_KEY: 'test-key', SEO_BLOG_AI_MODEL: 'test-model' };

test('SEO blog prompt targets safe, localized Swat transport content', () => {
  const prompt = createSeoBlogPrompt({ topic: 'transport_guide' });
  assert.match(prompt, /Swat Valley transport/i);
  assert.match(prompt, /Do not invent fares/i);
  assert.throws(() => createSeoBlogPrompt({ topic: 'unverified' }), /SEO_BLOG_TOPIC_UNSUPPORTED/);
});

test('SEO blog agent validates and normalizes AI drafts', async () => {
  const draft = await generateSeoBlogDraft({
    topic: 'local_ride_services', environment,
    fetchFn: async (url, options) => {
      assert.equal(url, environment.SEO_BLOG_AI_ENDPOINT);
      assert.equal(options.headers.authorization, 'Bearer test-key');
      return { ok: true, json: async () => ({ choices: [{ message: { content: JSON.stringify({ title: 'Getting Around Swat', slug: 'Getting Around Swat!', metaDescription: 'A practical guide to planning local rides and transport in Swat Valley for residents and visitors with clear, responsible travel advice.', keywords: ['Swat rides', 'Swat transport'], bodyMarkdown: '# Getting Around Swat' }) } }] }) };
    },
  });
  assert.deepEqual(draft, { title: 'Getting Around Swat', slug: 'getting-around-swat', metaDescription: 'A practical guide to planning local rides and transport in Swat Valley for residents and visitors with clear, responsible travel advice.', keywords: ['Swat rides', 'Swat transport'], bodyMarkdown: '# Getting Around Swat' });
});