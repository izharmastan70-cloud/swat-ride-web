import React from 'react';

export interface SchemaOrgProps {
  type: 'WebSite' | 'Organization' | 'LocalBusiness' | 'FAQPage' | 'Article' | 'SoftwareApplication' | 'TouristDestination';
  data: Record<string, any>;
}

export const SchemaOrg: React.FC<SchemaOrgProps> = ({ type, data }) => {
  const baseSchema: Record<string, any> = {
    '@context': 'https://schema.org',
    '@type': type,
    ...data,
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(baseSchema) }}
    />
  );
};

export const GLOBAL_ORGANIZATION_SCHEMA = {
  '@context': 'https://schema.org',
  '@type': 'Organization',
  name: 'SWAT RIDE',
  url: 'https://swatride.pk',
  logo: 'https://swatride.pk/logo.png',
  description: 'Your Trusted Premium Mobility & Ecosystem in Swat, Khyber Pakhtunkhwa, Pakistan.',
  address: {
    '@type': 'PostalAddress',
    addressLocality: 'Mingora',
    addressRegion: 'Khyber Pakhtunkhwa',
    addressCountry: 'PK',
  },
  contactPoint: {
    '@type': 'ContactPoint',
    contactType: 'customer support',
    email: 'support@swatride.pk',
    areaServed: 'PK',
    availableLanguage: ['English', 'Urdu', 'Pashto'],
  },
};

export const SOFTWARE_APP_SCHEMA = {
  '@context': 'https://schema.org',
  '@type': 'SoftwareApplication',
  name: 'SWAT RIDE - Mobility & Ecosystem',
  operatingSystem: 'ANDROID',
  applicationCategory: 'TravelAndLocalApplication',
  offers: {
    '@type': 'Offer',
    price: '0',
    priceCurrency: 'PKR',
  },
  description: 'Book normal rides, food delivery, cargo logistics, school transport, and Kalam 4x4 tours in Swat, KPK.',
};
