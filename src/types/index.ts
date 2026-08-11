export type Locale = 'en' | 'ur' | 'ps';

export interface LocalizedText {
  en: string;
  ur: string;
  ps: string;
  isLegalOrSafety?: boolean; // Flag to indicate human review required for legal/safety
}

export interface ServiceItem {
  id: string;
  slug: string;
  title: LocalizedText;
  shortDescription: LocalizedText;
  fullDescription: LocalizedText;
  iconName: string;
  badge?: LocalizedText;
  themeColor: string;
  features: LocalizedText[];
  howItWorks: {
    stepNumber: number;
    title: LocalizedText;
    description: LocalizedText;
  }[];
  ctaText: LocalizedText;
  ctaLink: string;
  secondaryCtaText?: LocalizedText;
  secondaryCtaLink?: string;
  safetyNote?: LocalizedText;
}

export interface PartnerRole {
  id: string;
  slug: string;
  title: LocalizedText;
  subtitle: LocalizedText;
  category: 'driver' | 'merchant' | 'guardian' | 'guide';
  iconName: string;
  benefits: {
    title: LocalizedText;
    description: LocalizedText;
    icon: string;
  }[];
  requirements: LocalizedText[];
  onboardingSteps: {
    step: number;
    title: LocalizedText;
    detail: LocalizedText;
  }[];
  earningsDisclaimer: LocalizedText;
  applyUrl: string;
}

export interface HelpCategory {
  id: string;
  slug: string;
  title: LocalizedText;
  description: LocalizedText;
  iconName: string;
  articleCount: number;
}

export interface HelpArticle {
  id: string;
  slug: string;
  categoryId: string;
  title: LocalizedText;
  summary: LocalizedText;
  content: LocalizedText;
  lastUpdated: string;
  isPopular?: boolean;
}

export interface VideoTutorial {
  id: string;
  slug: string;
  title: LocalizedText;
  description: LocalizedText;
  duration: string;
  thumbnailUrl: string;
  videoUrl: string;
  category: string;
  relatedServiceSlug?: string;
  relatedHelpSlug?: string;
  transcript: LocalizedText;
  captionsUrl?: string;
}

export interface BlogArticle {
  id: string;
  slug: string;
  title: string;
  subtitle: string;
  excerpt: string;
  content: string; // Markdown / HTML structure
  category: 'Swat Travel' | 'Tourism' | 'Hotels' | 'Transport' | 'Food' | 'Student Safety' | 'Driver Tips' | 'Local Guides' | 'SWAT RIDE Updates' | 'Safety';
  author: {
    name: string;
    role: string;
    avatarUrl: string;
  };
  publishedAt: string;
  updatedAt: string;
  readTime: string;
  coverImage: string;
  status: 'draft' | 'review' | 'approved' | 'scheduled' | 'published' | 'updated' | 'archived';
  tags: string[];
}

export interface LocationGuide {
  id: string;
  slug: string;
  name: string;
  urduName: string;
  tagline: string;
  description: string;
  altitude?: string;
  distanceFromMingora?: string;
  bestSeason: string;
  highlights: string[];
  recommendedTransport: string;
  availableServices: string[]; // e.g. ['ride', 'tours', 'hotels']
  imageUrl: string;
}

export interface NavItem {
  label: LocalizedText;
  href: string;
  isNew?: boolean;
  children?: {
    label: LocalizedText;
    href: string;
    description?: LocalizedText;
    iconName?: string;
  }[];
}

export interface AIReportPayload {
  reportType: 'daily_errors' | 'weekly_seo' | 'monthly_health';
  generatedAt: string;
  status: 'optimal' | 'warning' | 'error';
  summary: string;
  metrics: Record<string, string | number>;
  recommendations: string[];
}
