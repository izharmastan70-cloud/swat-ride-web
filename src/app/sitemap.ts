import { MetadataRoute } from 'next';
import { SWAT_SERVICES } from '@/data/services';
import { PARTNER_ROLES } from '@/data/partners';
import { BLOG_ARTICLES } from '@/data/blog';
import { SWAT_LOCATIONS } from '@/data/locations';

export default function sitemap(): MetadataRoute.Sitemap {
  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://swatride.pk';

  // Static core routes
  const staticRoutes = [
    '',
    '/ride',
    '/food',
    '/cargo',
    '/student-ride',
    '/hotels',
    '/tours',
    '/driver',
    '/restaurant-partner',
    '/food-rider',
    '/cargo-driver',
    '/parents',
    '/student-driver',
    '/hotel-partner',
    '/tourism-driver',
    '/tour-guide',
    '/safety',
    '/rewards',
    '/offers',
    '/help',
    '/help/videos',
    '/faq',
    '/contact',
    '/blog',
    '/about',
    '/careers',
    '/download',
    '/privacy',
    '/terms',
    '/refund-policy',
    '/cancellation-policy',
    '/community-guidelines',
  ].map((route) => ({
    url: `${baseUrl}${route}`,
    lastModified: new Date(),
    changeFrequency: 'weekly' as const,
    priority: route === '' ? 1.0 : route.startsWith('/blog') || route.startsWith('/help') ? 0.7 : 0.8,
  }));

  // Dynamic Blog Article Routes
  const blogRoutes = BLOG_ARTICLES.map((article) => ({
    url: `${baseUrl}/blog/${article.slug}`,
    lastModified: new Date(article.updatedAt),
    changeFrequency: 'monthly' as const,
    priority: 0.7,
  }));

  return [...staticRoutes, ...blogRoutes];
}
