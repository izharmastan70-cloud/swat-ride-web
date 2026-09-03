'use client';

import React from 'react';
import Link from 'next/link';
import {
  Mountain,
  MapPin,
  Compass,
  Users,
  Car,
  Hotel,
  ShieldCheck,
  CheckCircle2,
  Download,
  ArrowRight,
  ShieldAlert,
  Calendar,
  Star,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { CTASection } from '@/components/common/CTASection';
import { cn } from '@/lib/utils';

const FEATURED_PACKAGES = [
  {
    title: 'Kalam Valley & Ushu Forest Day Expedition',
    duration: '1 Day (10-12 Hours)',
    vehicle: '4x4 Mountain Jeep / Prado',
    route: 'Mingora → Bahrain → Kalam Town → Ushu Forest → Mingora',
    highlights: ['Ushu Deodar Forest Walk', 'Riverside Trout Lunch', 'Boyun Green Top Overlook'],
    image: 'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?auto=format&fit=crop&w=800&q=80',
  },
  {
    title: 'Mahodand Lake & Alpine Camping Trek',
    duration: '2 Days / 1 Night',
    vehicle: '4x4 Prado with Mountain Driver',
    route: 'Mingora → Kalam → Matiltan → Mahodand Lake (Overnight)',
    highlights: ['Alpine Glacial Lake Boating', 'Brown Trout Fishing', 'Falak Sar Peak Photography'],
    image: 'https://images.unsplash.com/photo-1501785888041-af3ef285b400?auto=format&fit=crop&w=800&q=80',
  },
  {
    id: 'malam-jabba-ski-retreat',
    title: 'Malam Jabba Ski Resort Family Weekend',
    duration: '2 Days / 1 Night',
    vehicle: 'High-Clearance Comfort Van / SUV',
    route: 'Mingora → Malam Jabba Ski Slopes → Luxury Alpine Resort',
    highlights: ['Ski Slopes & Chairlifts', 'Family Snow Play Area', '5-Star Resort Hospitality'],
    image: 'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?auto=format&fit=crop&w=800&q=80',
  },
];

export default function ToursServicePage() {
  const tourTopics = [
    {
      title: 'Top Swat Destinations',
      desc: 'Explore Kalam, Mahodand Lake, Malam Jabba, Ushu Forest, Gabin Jabba, and Mingora heritage monuments.',
      icon: <MapPin className="w-5 h-5 text-emerald-400" />,
    },
    {
      title: 'Custom Family & Group Tour Packages',
      desc: 'Choose from single-day sightseeing trips or multi-day alpine expeditions tailored to your family or corporate group.',
      icon: <Users className="w-5 h-5 text-emerald-400" />,
    },
    {
      title: 'Rugged 4x4 Mountain Vehicles',
      desc: 'We dispatch specialized 4x4 Jeeps, Prados, and Surfs engineered for unpaved high-altitude river trails.',
      icon: <Car className="w-5 h-5 text-emerald-400" />,
    },
    {
      title: 'Certified Multilingual Local Guides',
      desc: 'Every tour includes or can be paired with a certified local guide fluent in English, Urdu, and Pashto.',
      icon: <Compass className="w-5 h-5 text-emerald-400" />,
    },
    {
      title: 'Integrated Hotel Stays',
      desc: 'Your tour package seamlessly synchronizes with verified hotels and guest houses across Mingora and Kalam.',
      icon: <Hotel className="w-5 h-5 text-emerald-400" />,
    },
    {
      title: 'Uncompromising Mountain Safety & SOS',
      desc: 'All 4x4 drivers undergo strict high-altitude safety training, with 24/7 SOS tracking across challenging terrain.',
      icon: <ShieldAlert className="w-5 h-5 text-red-400" />,
    },
  ];

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Services', href: '/#services' },
            { label: 'Tours & Swat Tourism' },
          ]}
        />

        {/* Hero Banner */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center mb-20">
          <div className="lg:col-span-7 space-y-6">
            <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-950/80 border border-emerald-500/40 text-xs font-semibold text-emerald-300">
              <Mountain className="w-4 h-4 text-emerald-400" />
              <span>SWAT RIDE • Tourism & 4x4 Expeditions</span>
            </span>

            <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight leading-tight">
              Experience the Switzerland of the East with{' '}
              <span className="bg-gradient-to-r from-emerald-400 via-teal-300 to-amber-300 bg-clip-text text-transparent">
                4x4 Mountain Tours
              </span>
            </h1>

            <p className="text-base sm:text-lg text-mountain-300 leading-relaxed max-w-2xl">
              Discover Kalam Valley, Mahodand Lake, Ushu Forest, and Malam Jabba with rugged 4x4 Jeeps, certified multilingual tour guides, and integrated hotel packages. Engineered for safe, unforgettable family adventures.
            </p>

            <div className="flex flex-col sm:flex-row items-center gap-4 pt-2">
              <Link
                href="/download"
                className="inline-flex items-center justify-center gap-2.5 px-8 py-4 rounded-2xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-base shadow-lg shadow-emerald-600/30 transition-all w-full sm:w-auto"
              >
                <Download className="w-5 h-5" />
                <span>Explore Tour Packages in App</span>
              </Link>
              <Link
                href="/tourism-driver"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl bg-white/10 hover:bg-white/15 text-white font-semibold text-base border border-white/15 transition-all w-full sm:w-auto"
              >
                <span>Become a Tourism Driver</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          {/* Right: Featured Tour Package Visual */}
          <div className="lg:col-span-5">
            <div className="p-6 rounded-3xl bg-mountain-900 border border-mountain-800 shadow-glass-lg space-y-4">
              <div className="flex items-center justify-between border-b border-mountain-800 pb-3">
                <h3 className="text-base font-bold text-white">Popular Kalam 4x4 Expedition</h3>
                <span className="text-xs text-emerald-400 font-semibold">Featured Route</span>
              </div>

              <div className="rounded-2xl overflow-hidden relative h-48 bg-mountain-800">
                <img
                  src="/images/swat-4x4-jeep.jpg"
                  alt="Kalam & Mahodand 4x4 Jeep"
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-mountain-950 via-transparent to-transparent" />
                <span className="absolute bottom-3 left-3 px-3 py-1 text-xs font-bold rounded-full bg-mountain-950/90 text-white border border-white/20">
                  9,400 ft • Mahodand Glacial Lake
                </span>
              </div>

              <div className="space-y-2 text-xs text-mountain-300">
                <div className="flex items-center justify-between">
                  <span className="font-semibold text-white">Vehicle Tier:</span>
                  <span className="text-emerald-400 font-bold">4x4 Jeep / Prado</span>
                </div>
                <div className="flex items-center justify-between">
                  <span className="font-semibold text-white">Guide Support:</span>
                  <span>Certified Multilingual Guide Included</span>
                </div>
              </div>

              <div className="text-center pt-2">
                <Link
                  href="/download"
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-emerald-400 hover:text-emerald-300 transition-colors"
                >
                  <span>Book Custom Itineraries in App</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>
            </div>
          </div>
        </div>

        {/* Featured Packages Grid */}
        <SectionHeader
          badge="Curated Expeditions"
          title="Featured Swat Tourism Packages"
          subtitle="All packages include verified 4x4 vehicles, certified drivers, and optional local guide accompaniment."
        />

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-20">
          {FEATURED_PACKAGES.map((pkg, idx) => (
            <div
              key={idx}
              className="rounded-2xl bg-mountain-900 border border-mountain-800 hover:border-emerald-500/40 overflow-hidden transition-all flex flex-col justify-between shadow-glass-sm"
            >
              <div className="h-48 bg-mountain-800 relative overflow-hidden">
                <img src={pkg.image} alt={pkg.title} className="w-full h-full object-cover" />
                <span className="absolute top-3 left-3 px-3 py-1 text-xs font-bold rounded-full bg-mountain-950/90 text-emerald-300 border border-emerald-500/30">
                  {pkg.duration}
                </span>
              </div>

              <div className="p-6 space-y-4 flex-1 flex flex-col justify-between">
                <div>
                  <h3 className="text-xl font-bold text-white mb-2">{pkg.title}</h3>
                  <p className="text-xs text-mountain-400 font-semibold mb-3">
                    Route: {pkg.route}
                  </p>
                  <ul className="space-y-1.5 text-xs text-mountain-300">
                    {pkg.highlights.map((hl, i) => (
                      <li key={i} className="flex items-center gap-2">
                        <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400 shrink-0" />
                        <span>{hl}</span>
                      </li>
                    ))}
                  </ul>
                </div>

                <div className="pt-4 border-t border-mountain-800/80 flex items-center justify-between">
                  <span className="text-xs font-bold text-emerald-400">{pkg.vehicle}</span>
                  <Link
                    href="/download"
                    className="text-xs font-semibold px-3 py-1.5 rounded-lg bg-emerald-600/20 hover:bg-emerald-600/40 text-emerald-300 border border-emerald-500/30 transition-colors"
                  >
                    Book Package
                  </Link>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* 6 Core Pillars of Swat Tourism */}
        <SectionHeader
          badge="Complete Ecosystem"
          title="Why SWAT RIDE is Swat’s #1 Mountain Tourism Partner"
          subtitle="We combine rugged transport, heritage storytelling, and hotel integration in a single verified platform."
        />

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-20">
          {tourTopics.map((item, idx) => (
            <div
              key={idx}
              className="p-6 rounded-2xl bg-mountain-900/80 border border-mountain-800 hover:border-emerald-500/40 transition-all space-y-3"
            >
              <div className="w-10 h-10 rounded-xl bg-mountain-950/80 border border-mountain-800 flex items-center justify-center">
                {item.icon}
              </div>
              <h3 className="text-lg font-bold text-white">{item.title}</h3>
              <p className="text-sm text-mountain-300 leading-relaxed">{item.desc}</p>
            </div>
          ))}
        </div>

        {/* Dual CTA for Tourism Drivers & Tour Guides */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div className="p-8 rounded-3xl bg-gradient-to-br from-mountain-900 to-mountain-950 border border-mountain-800 space-y-4">
            <Car className="w-10 h-10 text-emerald-400" />
            <h3 className="text-2xl font-bold text-white">Own a 4x4 Jeep or Prado?</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              Accept high-altitude expedition bookings for Kalam, Ushu Forest, and Mahodand Lake. Earn premium tourism rates with weekly transparent payouts.
            </p>
            <Link
              href="/tourism-driver"
              className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-emerald-600 text-white font-bold text-sm transition-all"
            >
              <span>Apply as Tourism Driver</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>

          <div className="p-8 rounded-3xl bg-gradient-to-br from-mountain-900 to-mountain-950 border border-mountain-800 space-y-4">
            <Compass className="w-10 h-10 text-amber-400" />
            <h3 className="text-2xl font-bold text-white">Become a Certified Tour Guide</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              Fluent in English, Pashto, or Urdu? Share Swat’s Gandhara heritage and alpine trails with visitors and earn professional storytelling fees.
            </p>
            <Link
              href="/tour-guide"
              className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-amber-500 text-mountain-950 font-bold text-sm transition-all"
            >
              <span>Apply as Tour Guide</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
