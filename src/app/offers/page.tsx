'use client';

import React from 'react';
import Link from 'next/link';
import {
  Tag,
  CheckCircle2,
  Copy,
  Download,
  ArrowRight,
  Sparkles,
  Calendar,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { CTASection } from '@/components/common/CTASection';

const CURRENT_OFFERS = [
  {
    code: 'SWATWELCOME',
    title: 'New User Introductory Ride Discount',
    desc: 'Enjoy special savings on your first 3 Normal Ride bookings across Mingora and Saidu Sharif.',
    validity: 'Valid for New Registrations',
    tag: 'Welcome Voucher',
  },
  {
    title: 'Kalam 4x4 Summer Tour Voucher',
    code: 'KALAM2026',
    desc: 'Seasonal discount on full-day mountain Jeep bookings to Ushu Forest and Mahodand Lake.',
    validity: 'Summer Tourism Peak Season',
    tag: 'Tourism Offer',
  },
  {
    title: 'Mingora Trout Feast Delivery Deal',
    code: 'SWATFOOD',
    desc: 'Free delivery on qualifying food orders from verified Fiza Gat and Mingora trout restaurants.',
    validity: 'Weekend Specials',
    tag: 'Food Delivery',
  },
];

export default function OffersPage() {
  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Rewards & Offers', href: '/rewards' },
            { label: 'Current Swat Promo Codes & Offers' },
          ]}
        />

        {/* Hero */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-6">
          <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-swat-950/80 border border-swat-500/40 text-xs font-semibold text-swat-300">
            <Tag className="w-4 h-4 text-swat-400" />
            <span>SWAT RIDE • Seasonal Promotions</span>
          </span>

          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            Current Promo Codes & Seasonal Swat Deals
          </h1>

          <p className="text-base text-mountain-300 leading-relaxed">
            Apply these official promo codes at checkout inside your SWAT RIDE Android app to save on rides, hot food delivery, and mountain 4x4 tourism packages.
          </p>
        </div>

        {/* Offers Grid */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-20">
          {CURRENT_OFFERS.map((offer, idx) => (
            <div
              key={idx}
              className="p-8 rounded-3xl bg-mountain-900 border border-mountain-800 hover:border-swat-500/50 transition-all flex flex-col justify-between space-y-6 shadow-glass-sm"
            >
              <div className="space-y-3">
                <div className="flex items-center justify-between">
                  <span className="px-2.5 py-1 text-xs font-bold rounded-lg bg-swat-600/20 text-swat-300 border border-swat-500/30">
                    {offer.tag}
                  </span>
                  <span className="text-xs text-mountain-400">{offer.validity}</span>
                </div>
                <h3 className="text-xl font-bold text-white">{offer.title}</h3>
                <p className="text-sm text-mountain-300 leading-relaxed">{offer.desc}</p>
              </div>

              <div className="p-4 rounded-2xl bg-mountain-950 border border-mountain-800 flex items-center justify-between">
                <div>
                  <span className="text-[10px] uppercase text-mountain-400 font-semibold block">
                    Promo Code
                  </span>
                  <span className="font-mono font-bold text-swat-400 text-base">
                    {offer.code}
                  </span>
                </div>
                <Link
                  href="/download"
                  className="px-4 py-2 rounded-xl bg-swat-600 hover:bg-swat-500 text-white text-xs font-bold transition-all"
                >
                  Use in App
                </Link>
              </div>
            </div>
          ))}
        </div>

        <CTASection />
      </div>
    </div>
  );
}
