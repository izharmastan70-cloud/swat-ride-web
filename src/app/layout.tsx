import type { Metadata } from 'next';
import React from 'react';
import { Inter } from 'next/font/google';
import './globals.css';
import { Header } from '@/components/layout/Header';
import { Footer } from '@/components/layout/Footer';
import { SchemaOrg, GLOBAL_ORGANIZATION_SCHEMA, SOFTWARE_APP_SCHEMA } from '@/components/common/SchemaOrg';

const inter = Inter({ subsets: ['latin'], variable: '--font-inter', display: 'swap' });

export const metadata: Metadata = {
  title: {
    default: 'SWAT RIDE — Your Trusted Premium Mobility & Ecosystem in Swat, KPK',
    template: '%s | SWAT RIDE',
  },
  description:
    'SWAT RIDE connects Swat Valley with reliable normal rides, hot food delivery, cargo logistics, monthly student school transport, hotels, and 4x4 Kalam mountain tours.',
  keywords: [
    'SWAT RIDE',
    'Swat Taxi',
    'Mingora Ride',
    'Swat Food Delivery',
    'Kalam 4x4 Tours',
    'Mahodand Lake Jeep',
    'Saidu Sharif Transport',
    'Student School Van Swat',
    'Hotels in Malam Jabba',
    'Khyber Pakhtunkhwa Tourism',
  ],
  authors: [{ name: 'SWAT RIDE Engineering & Design Desk' }],
  metadataBase: new URL(process.env.NEXT_PUBLIC_SITE_URL || 'https://swatride.pk'),
  openGraph: {
    title: 'SWAT RIDE — Mobility & Ecosystem in Swat, KPK',
    description:
      'Experience transparent upfront fares, verified local Swat drivers, 24/7 SOS safety, food delivery, and scenic mountain tours.',
    url: 'https://swatride.pk',
    siteName: 'SWAT RIDE',
    locale: 'en_PK',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'SWAT RIDE — Your Trusted Mobility Ecosystem in Swat, KPK',
    description: 'Upfront fare estimates, verified drivers, food delivery, school transport, and Kalam 4x4 tours.',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-video-preview': -1,
      'max-image-preview': 'large',
      'max-snippet': -1,
    },
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${inter.variable} bg-mountain-950 text-white antialiased`}>
      <head>
        <link rel="canonical" href="https://swatride.pk" />
      </head>
      <body className="min-h-screen flex flex-col bg-mountain-950 text-white selection:bg-swat-500 selection:text-white">
        <SchemaOrg type="Organization" data={GLOBAL_ORGANIZATION_SCHEMA} />
        <SchemaOrg type="SoftwareApplication" data={SOFTWARE_APP_SCHEMA} />
        <Header />
        <main className="flex-1">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
