import { MetadataRoute } from 'next';

export default function robots(): MetadataRoute.Robots {
  const baseUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://swatride.pk';

  return {
    rules: [
      {
        userAgent: '*',
        allow: '/',
        disallow: [
          '/api/',
          '/admin/',
          '/drafts/',
          '/private/',
          '/_next/',
          '/cdn-cgi/',
        ],
      },
    ],
    sitemap: `${baseUrl}/sitemap.xml`,
  };
}
