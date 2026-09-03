const ALLOWED_PLATFORMS = new Set(['facebook', 'instagram', 'tiktok', 'youtube']);
const MAX_TOPIC_LENGTH = 180;

function cleanText(value, fallback = '') {
  return typeof value === 'string' ? value.trim() : fallback;
}

export function createSocialContentDraft({ platform, topic, language = 'en' } = {}) {
  const normalizedPlatform = cleanText(platform).toLowerCase();
  const normalizedTopic = cleanText(topic, 'Explore Swat with confidence');
  const normalizedLanguage = cleanText(language, 'en').toLowerCase();
  if (!ALLOWED_PLATFORMS.has(normalizedPlatform)) throw new Error('SOCIAL_PLATFORM_UNSUPPORTED');
  if (!normalizedTopic || normalizedTopic.length > MAX_TOPIC_LENGTH) throw new Error('SOCIAL_TOPIC_INVALID');

  const hook = 'Swat is calling. Travel it with confidence.';
  const caption = `${hook}\n\n${normalizedTopic}. From scenic valleys to everyday city travel, Swat Ride helps locals and visitors book a safe, affordable ride in a few taps.\n\nOpen Swat Ride, choose your pickup and destination, and follow your trip in the app.`;
  const title = normalizedPlatform === 'youtube'
    ? 'Discover Swat with Swat Ride'
    : 'Explore Swat, ride with confidence';
  const script = [
    { seconds: '0-3', visual: 'Real daylight footage of Swat valley or a verified local landmark.', narration: hook },
    { seconds: '3-9', visual: 'Passenger opens Swat Ride and enters pickup and destination.', narration: 'Easy booking for locals and tourists, right when you need to travel.' },
    { seconds: '9-15', visual: 'Verified driver vehicle arrives; show a genuine app trip screen.', narration: 'Affordable fares, safer rides, and live trip updates inside the Swat Ride app.' },
    { seconds: '15-20', visual: 'Arrival at a real Swat destination with clear consent for every person filmed.', narration: 'See more of Swat. Ride smarter with Swat Ride.' },
  ];

  return Object.freeze({
    platform: normalizedPlatform,
    language: normalizedLanguage,
    title,
    caption,
    script,
    hashtags: ['#SwatRide', '#SwatValley', '#ExploreSwat', '#TravelPakistan'],
    visualGuidance: 'Use only real, owned, licensed, or explicitly approved images and video. Do not claim unverified pricing, availability, or safety outcomes.',
    status: 'draft',
  });
}