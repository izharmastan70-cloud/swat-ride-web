import React from 'react';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import {
  MapPin,
  Mountain,
  Car,
  Hotel,
  Compass,
  ArrowLeft,
  CheckCircle2,
  AlertTriangle,
  Download,
  Share2,
} from 'lucide-react';
import { SWAT_LOCATIONS } from '@/data/locations';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { CTASection } from '@/components/common/CTASection';
import { SchemaOrg } from '@/components/common/SchemaOrg';

interface SwatDestinationPageProps {
  params: {
    slug: string;
  };
}

export async function generateStaticParams() {
  return SWAT_LOCATIONS.map((loc) => ({
    slug: loc.slug,
  }));
}

export default function SwatDestinationDetailPage({ params }: SwatDestinationPageProps) {
  const location = SWAT_LOCATIONS.find((l) => l.slug === params.slug);
  if (!location) return notFound();

  const touristSchema = {
    name: `${location.name} (${location.urduName})`,
    description: location.description,
    image: location.imageUrl,
    address: {
      '@type': 'PostalAddress',
      addressLocality: location.name,
      addressRegion: 'Khyber Pakhtunkhwa',
      addressCountry: 'PK',
    },
    touristType: ['Family travel', 'Mountain adventure', 'Cultural heritage'],
  };

  return (
    <div className="relative py-12 sm:py-16">
      <SchemaOrg type="TouristDestination" data={touristSchema} />

      <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Explore Swat', href: '/swat' },
            { label: `${location.name} Guide` },
          ]}
        />

        {/* Header */}
        <div className="space-y-6 mb-12">
          <div className="flex flex-wrap items-center gap-2">
            <span className="px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-emerald-600/20 text-emerald-300 border border-emerald-500/30">
              {location.altitude}
            </span>
            <span className="px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-white/10 text-white border border-white/15">
              Distance: {location.distanceFromMingora}
            </span>
          </div>

          <div className="flex items-center justify-between">
            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black text-white tracking-tight">
              {location.name}
            </h1>
            <span className="text-2xl sm:text-3xl font-nastaliq text-mountain-400">
              {location.urduName}
            </span>
          </div>

          <p className="text-lg text-mountain-300 leading-relaxed">
            {location.tagline}
          </p>
        </div>

        {/* Hero Image */}
        <div className="rounded-3xl overflow-hidden mb-12 bg-mountain-900 border border-mountain-800 h-[340px] sm:h-[420px]">
          <img
            src={location.imageUrl}
            alt={location.name}
            className="w-full h-full object-cover"
          />
        </div>

        {/* Overview & Highlights Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 mb-16">
          <div className="lg:col-span-7 space-y-6">
            <h2 className="text-2xl font-extrabold text-white">About {location.name}</h2>
            <p className="text-base text-mountain-200 leading-relaxed">
              {location.description}
            </p>

            <div className="space-y-4 pt-4">
              <h3 className="text-lg font-bold text-white">Top Highlights & Landmarks</h3>
              <ul className="space-y-2.5">
                {location.highlights.map((hl, idx) => (
                  <li key={idx} className="flex items-start gap-3 text-sm text-mountain-200">
                    <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0 mt-0.5" />
                    <span>{hl}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          {/* Right Transport & Season Card */}
          <div className="lg:col-span-5">
            <div className="p-8 rounded-3xl bg-mountain-900 border border-mountain-800 space-y-6 shadow-glass-lg">
              <h3 className="text-lg font-bold text-white border-b border-mountain-800 pb-4">
                Travel & Transport Guidance
              </h3>

              <div className="space-y-4 text-sm">
                <div>
                  <span className="text-xs font-semibold text-mountain-400 uppercase block">
                    Best Season to Visit
                  </span>
                  <span className="font-bold text-white block mt-1">
                    {location.bestSeason}
                  </span>
                </div>

                <div>
                  <span className="text-xs font-semibold text-mountain-400 uppercase block">
                    Recommended Transport Tier
                  </span>
                  <span className="font-bold text-emerald-400 block mt-1">
                    {location.recommendedTransport}
                  </span>
                </div>

                <div>
                  <span className="text-xs font-semibold text-mountain-400 uppercase block">
                    Available SWAT RIDE Services
                  </span>
                  <div className="flex flex-wrap gap-1.5 mt-2">
                    {location.availableServices.map((srv, idx) => (
                      <span
                        key={idx}
                        className="px-2.5 py-1 rounded-lg bg-mountain-950 text-mountain-200 text-xs font-semibold uppercase"
                      >
                        {srv}
                      </span>
                    ))}
                  </div>
                </div>
              </div>

              <div className="p-4 rounded-2xl bg-mountain-950 border border-mountain-800 text-xs text-mountain-300 space-y-1">
                <div className="font-bold text-white flex items-center gap-1.5">
                  <AlertTriangle className="w-4 h-4 text-amber-400" />
                  <span>Road Condition Advisory</span>
                </div>
                <p>
                  Always verify weather advisories before traveling to high-altitude areas like {location.name} during snowfall months.
                </p>
              </div>

              <Link
                href="/download"
                className="flex items-center justify-center gap-2 w-full py-3.5 px-4 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-sm shadow-lg shadow-emerald-600/30 transition-all"
              >
                <Download className="w-4 h-4" />
                <span>Book {location.name} Transport in App</span>
              </Link>
            </div>
          </div>
        </div>

        {/* Back Link */}
        <div className="py-6 border-t border-mountain-800 mb-16">
          <Link
            href="/swat"
            className="inline-flex items-center gap-2 text-sm font-bold text-emerald-400 hover:text-emerald-300 transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to All Swat Destinations</span>
          </Link>
        </div>

        <CTASection />
      </div>
    </div>
  );
}
