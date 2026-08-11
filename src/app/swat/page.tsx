'use client';

import React from 'react';
import Link from 'next/link';
import {
  MapPin,
  Mountain,
  Car,
  Hotel,
  Compass,
  ArrowRight,
  ShieldCheck,
  Navigation,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { SWAT_LOCATIONS } from '@/data/locations';

export default function SwatDestinationsPage() {
  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Explore Swat', href: '/swat' },
            { label: 'KPK Regional Destination Guides' },
          ]}
        />

        {/* Hero Section */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-6">
          <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-950/80 border border-emerald-500/40 text-xs font-semibold text-emerald-300">
            <Mountain className="w-4 h-4 text-emerald-400" />
            <span>SWAT RIDE • Local KPK Destination Guides</span>
          </span>

          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            Explore Swat Valley from Mingora to Mahodand Lake
          </h1>

          <p className="text-base text-mountain-300 leading-relaxed">
            Genuine, verified travel guides covering road accessibility, altitude, recommended transport tiers, and local highlights. We never fabricate weather or road conditions.
          </p>
        </div>

        {/* 9 Regional Destinations Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-20">
          {SWAT_LOCATIONS.map((loc) => (
            <div
              key={loc.id}
              className="group rounded-2xl bg-mountain-900 border border-mountain-800 hover:border-emerald-500/50 overflow-hidden shadow-glass-sm transition-all duration-300 flex flex-col justify-between"
            >
              <div className="h-48 bg-mountain-800 relative overflow-hidden">
                <img
                  src={loc.imageUrl}
                  alt={loc.name}
                  className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-mountain-950 via-transparent to-transparent" />
                <span className="absolute top-3 left-3 px-2.5 py-1 text-xs font-bold rounded-md bg-mountain-950/90 text-white border border-white/10">
                  {loc.altitude}
                </span>
                <span className="absolute bottom-3 right-3 font-nastaliq text-base text-white">
                  {loc.urduName}
                </span>
              </div>

              <div className="p-6 space-y-4 flex-1 flex flex-col justify-between">
                <div>
                  <h3 className="text-xl font-bold text-white group-hover:text-emerald-300 transition-colors">
                    {loc.name}
                  </h3>
                  <p className="text-xs text-mountain-400 font-semibold mt-1">
                    {loc.tagline}
                  </p>
                  <p className="text-sm text-mountain-300 mt-2 leading-relaxed line-clamp-3">
                    {loc.description}
                  </p>
                </div>

                <div className="pt-4 border-t border-mountain-800/80 space-y-3">
                  <div className="flex items-center justify-between text-xs text-mountain-400">
                    <span>Season: {loc.bestSeason.split('(')[0].trim()}</span>
                    <span className="text-emerald-400 font-bold">{loc.recommendedTransport.split('(')[0].trim()}</span>
                  </div>

                  <Link
                    href={`/swat/${loc.slug}`}
                    className="inline-flex items-center justify-between w-full p-2.5 rounded-xl bg-mountain-950/80 hover:bg-emerald-600/20 border border-mountain-800 hover:border-emerald-500/40 text-xs font-bold text-white hover:text-emerald-300 transition-all"
                  >
                    <span>View Full {loc.name} Guide</span>
                    <ArrowRight className="w-3.5 h-3.5" />
                  </Link>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Local Verification Notice */}
        <div className="p-8 rounded-3xl bg-mountain-900 border border-mountain-800 text-center space-y-2">
          <div className="flex items-center justify-center gap-2 font-bold text-white text-sm">
            <ShieldCheck className="w-4 h-4 text-emerald-400" />
            <span>Local Accuracy Guarantee</span>
          </div>
          <p className="text-xs text-mountain-400 max-w-lg mx-auto">
            Our destination guides are maintained in Mingora. For winter snow blockages on Malam Jabba or Mahodand Lake routes, always check live in-app advisories before booking 4x4 vehicles.
          </p>
        </div>
      </div>
    </div>
  );
}
