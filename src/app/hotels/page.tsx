'use client';

import React from 'react';
import Link from 'next/link';
import {
  Hotel,
  MapPin,
  CheckCircle2,
  Calendar,
  CreditCard,
  RefreshCw,
  Download,
  ArrowRight,
  ShieldCheck,
  Star,
  Car,
  Wifi,
  Coffee,
  ShieldAlert,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { CTASection } from '@/components/common/CTASection';
import { cn } from '@/lib/utils';

const DEMO_HOTELS = [
  {
    id: 'malam-jabba-alpine-resort',
    name: 'Malam Jabba Alpine Lodge',
    location: 'Malam Jabba Ski Slope Road, Swat',
    rating: 'Verified Partner',
    amenities: ['Free Wi-Fi', 'Mountain View', 'Family Suites', 'Ski Access'],
    image: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80',
    availabilityNote: 'Real-time booking calendar via app',
  },
  {
    id: 'kalam-river-palace',
    name: 'Kalam Riverside Retreat',
    location: 'Main Kalam Bazaar Road, Upper Swat',
    rating: 'Verified Partner',
    amenities: ['River Front Balcony', 'Trout Dining', '4x4 Parking', '24/7 Security'],
    image: 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?auto=format&fit=crop&w=600&q=80',
    availabilityNote: 'Real-time booking calendar via app',
  },
  {
    id: 'mingora-executive-suites',
    name: 'Mingora Central Executive Suites',
    location: 'Saidu Sharif Junction, Mingora',
    rating: 'Verified Partner',
    amenities: ['Business Center', 'AC / Heating', 'City Transit Hub', 'Free Breakfast'],
    image: 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?auto=format&fit=crop&w=600&q=80',
    availabilityNote: 'Real-time booking calendar via app',
  },
];

export default function HotelsServicePage() {
  const hotelTopics = [
    {
      title: 'Verified Hotel Discovery & Location',
      desc: 'Explore genuine hospitality partners in Mingora, Malam Jabba, Bahrain, and Kalam with exact GPS coordinates and photo verification.',
      icon: <MapPin className="w-5 h-5 text-teal-400" />,
    },
    {
      title: 'Transparent Rooms, Prices & Amenities',
      desc: 'Review verified room amenities (Wi-Fi, heating, family suites, mountain balconies) with zero hidden service charges.',
      icon: <Hotel className="w-5 h-5 text-teal-400" />,
    },
    {
      title: 'Authentic Real-Time Availability',
      desc: 'We never fabricate room availability. You book directly from verified property calendars with instant digital vouchers.',
      icon: <Calendar className="w-5 h-5 text-teal-400" />,
    },
    {
      title: 'Seamless Transit to Your Hotel Doorstep',
      desc: 'Combine your stay booking with an instant SWAT RIDE Normal Ride or Kalam 4x4 mountain transit transfer.',
      icon: <Car className="w-5 h-5 text-teal-400" />,
    },
    {
      title: 'Flexible Payments & Clear Cancellation',
      desc: 'Pay via bank card, mobile wallet, or cash on arrival with clearly published refund and cancellation rules.',
      icon: <RefreshCw className="w-5 h-5 text-teal-400" />,
    },
    {
      title: '24/7 Hospitality Support Desk',
      desc: 'Our Mingora travel support team is available 24/7 to resolve any booking modification or check-in inquiry.',
      icon: <ShieldCheck className="w-5 h-5 text-teal-400" />,
    },
  ];

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Services', href: '/#services' },
            { label: 'Hotels & Stays' },
          ]}
        />

        {/* Hero Section */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center mb-20">
          <div className="lg:col-span-7 space-y-6">
            <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-teal-950/80 border border-teal-500/40 text-xs font-semibold text-teal-300">
              <Hotel className="w-4 h-4 text-teal-400" />
              <span>SWAT RIDE • Verified Hospitality Network</span>
            </span>

            <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight leading-tight">
              Discover & Book Verified Hotels Across{' '}
              <span className="bg-gradient-to-r from-teal-400 to-emerald-300 bg-clip-text text-transparent">
                Swat Valley
              </span>
            </h1>

            <p className="text-base sm:text-lg text-mountain-300 leading-relaxed max-w-2xl">
              From business hotels in central Mingora to scenic mountain resorts in Kalam and Malam Jabba. We guarantee authentic room listings, transparent pricing, and zero fabricated availability.
            </p>

            <div className="flex flex-col sm:flex-row items-center gap-4 pt-2">
              <Link
                href="/download"
                className="inline-flex items-center justify-center gap-2.5 px-8 py-4 rounded-2xl bg-teal-600 hover:bg-teal-500 text-white font-bold text-base shadow-lg shadow-teal-600/30 transition-all w-full sm:w-auto"
              >
                <Download className="w-5 h-5" />
                <span>Book Hotels in App</span>
              </Link>
              <Link
                href="/hotel-partner"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl bg-white/10 hover:bg-white/15 text-white font-semibold text-base border border-white/15 transition-all w-full sm:w-auto"
              >
                <span>Partner Your Hotel</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          {/* Right: Featured Properties Showcase */}
          <div className="lg:col-span-5">
            <div className="p-6 rounded-3xl bg-mountain-900 border border-mountain-800 shadow-glass-lg space-y-4">
              <div className="flex items-center justify-between border-b border-mountain-800 pb-3">
                <h3 className="text-base font-bold text-white">Featured Swat Stays</h3>
                <span className="text-xs text-teal-400 font-semibold">Verified Properties</span>
              </div>

              <div className="space-y-4">
                {DEMO_HOTELS.map((hotel) => (
                  <div
                    key={hotel.id}
                    className="flex items-center gap-4 p-3 rounded-2xl bg-mountain-950/80 border border-mountain-800 hover:border-teal-500/40 transition-all"
                  >
                    <img
                      src={hotel.image}
                      alt={hotel.name}
                      className="w-16 h-16 rounded-xl object-cover shrink-0"
                    />
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center justify-between">
                        <h4 className="text-sm font-bold text-white truncate">{hotel.name}</h4>
                        <span className="text-[10px] text-teal-400 font-semibold">{hotel.rating}</span>
                      </div>
                      <p className="text-xs text-mountain-400 truncate">{hotel.location}</p>
                      <div className="flex flex-wrap gap-1 mt-1">
                        {hotel.amenities.slice(0, 2).map((am, i) => (
                          <span
                            key={i}
                            className="px-1.5 py-0.5 text-[9px] rounded bg-mountain-800 text-mountain-300"
                          >
                            {am}
                          </span>
                        ))}
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              <div className="text-center pt-2">
                <Link
                  href="/download"
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-teal-400 hover:text-teal-300 transition-colors"
                >
                  <span>Explore Rooms & Check Availability in App</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>
            </div>
          </div>
        </div>

        {/* 6 Core Hotel Topics */}
        <SectionHeader
          badge="Verified Stays"
          title="Why Book Your Swat Hotel with SWAT RIDE"
          subtitle="No fake reviews, no artificial scarcity alarms—just transparent room information and integrated transport."
        />

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-20">
          {hotelTopics.map((item, idx) => (
            <div
              key={idx}
              className="p-6 rounded-2xl bg-mountain-900/80 border border-mountain-800 hover:border-teal-500/40 transition-all space-y-3"
            >
              <div className="w-10 h-10 rounded-xl bg-mountain-950/80 border border-mountain-800 flex items-center justify-center">
                {item.icon}
              </div>
              <h3 className="text-lg font-bold text-white">{item.title}</h3>
              <p className="text-sm text-mountain-300 leading-relaxed">{item.desc}</p>
            </div>
          ))}
        </div>

        <CTASection
          title="Planning a Trip to Swat Valley?"
          subtitle="Download the SWAT RIDE app to discover hotels, check real-time availability, and book your mountain transport."
          primaryCtaText="Book Hotels in App"
          primaryCtaLink="/download"
          secondaryCtaText="Register Hotel Property"
          secondaryCtaLink="/hotel-partner"
        />
      </div>
    </div>
  );
}
