'use client';

import React from 'react';
import Link from 'next/link';
import {
  Car,
  ShieldCheck,
  Heart,
  MapPin,
  Users,
  TrendingUp,
  Download,
  ArrowRight,
  CheckCircle2,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { CTASection } from '@/components/common/CTASection';

export default function AboutPage() {
  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Company', href: '/about' },
            { label: 'About SWAT RIDE' },
          ]}
        />

        {/* Hero */}
        <div className="text-center max-w-3xl mx-auto mb-20 space-y-6">
          <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-swat-950/80 border border-swat-500/40 text-xs font-semibold text-swat-300">
            <Car className="w-4 h-4 text-swat-400" />
            <span>SWAT RIDE • Our Regional Mission</span>
          </span>

          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            Engineered in Swat, For Swat & Khyber Pakhtunkhwa
          </h1>

          <p className="text-base sm:text-lg text-mountain-300 leading-relaxed">
            SWAT RIDE was born from a simple conviction: the people and visitors of Swat Valley deserve a modern, transparent mobility platform that understands local roads, respects community customs, and creates genuine regional livelihoods.
          </p>
        </div>

        {/* Core Pillars */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-20">
          <div className="p-8 rounded-3xl bg-mountain-900 border border-mountain-800 space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-swat-600/20 text-swat-400 border border-swat-500/30 flex items-center justify-center">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-white">Trust & Upfront Transparency</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              We eliminated fare bargaining and hidden surcharges. Our upfront fare estimates ensure that passengers and drivers always agree before a journey begins.
            </p>
          </div>

          <div className="p-8 rounded-3xl bg-mountain-900 border border-mountain-800 space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-amber-500/20 text-amber-400 border border-amber-500/30 flex items-center justify-center">
              <Heart className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-white">Regional Livelihoods</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              We partner with local Swat drivers, food riders, restaurant owners, hotel partners, and multilingual tour guides to foster sustainable economic growth across KPK.
            </p>
          </div>

          <div className="p-8 rounded-3xl bg-mountain-900 border border-mountain-800 space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 flex items-center justify-center">
              <MapPin className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-white">Terrain-Ready Engineering</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              From Mingora city streets to high-altitude 4x4 mountain tracks leading to Kalam and Mahodand Lake, our dispatch system matches the right vehicle to the right terrain.
            </p>
          </div>
        </div>

        {/* Headquarters Banner */}
        <div className="p-8 sm:p-12 rounded-3xl bg-gradient-to-r from-mountain-900 via-mountain-950 to-swat-950/50 border border-mountain-800 shadow-glass-lg mb-20 text-center space-y-4">
          <h2 className="text-3xl font-extrabold text-white">Our Mingora Regional Desk</h2>
          <p className="text-sm text-mountain-300 max-w-xl mx-auto leading-relaxed">
            Every driver, restaurant partner, and tour guide is verified in-person at our central Mingora office. We believe technology should strengthen—not replace—human connection and accountability.
          </p>
          <div className="pt-2">
            <Link
              href="/contact"
              className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-swat-600 hover:bg-swat-500 text-white font-bold text-sm transition-all"
            >
              <span>Contact Regional Headquarters</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>

        <CTASection />
      </div>
    </div>
  );
}
