'use client';

import React from 'react';
import Link from 'next/link';
import {
  Gift,
  Award,
  CheckCircle2,
  DollarSign,
  Download,
  ArrowRight,
  Sparkles,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { CTASection } from '@/components/common/CTASection';

export default function RewardsPage() {
  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Rewards & Offers', href: '/rewards' },
            { label: 'SWAT RIDE Loyalty & Points' },
          ]}
        />

        {/* Hero */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-6">
          <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-950/80 border border-amber-500/40 text-xs font-semibold text-amber-300">
            <Gift className="w-4 h-4 text-amber-400" />
            <span>SWAT RIDE • Swat Loyalty Program</span>
          </span>

          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            Earn Loyalty Points on Every Ride, Meal & Tour
          </h1>

          <p className="text-base text-mountain-300 leading-relaxed">
            Every completed booking in the SWAT RIDE app automatically earns Swat Points. Redeem your points for ride credits, restaurant vouchers, or Kalam mountain tour discounts across Swat District.
          </p>
        </div>

        {/* How to Earn Points */}
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-20">
          <div className="p-8 rounded-3xl bg-mountain-900 border border-mountain-800 space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-amber-500/20 text-amber-400 border border-amber-500/30 flex items-center justify-center">
              <Award className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-white">1. Book Normal Rides</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              Earn base loyalty points for every completed trip across Mingora, Saidu Sharif, and Bahrain.
            </p>
          </div>

          <div className="p-8 rounded-3xl bg-mountain-900 border border-mountain-800 space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-amber-500/20 text-amber-400 border border-amber-500/30 flex items-center justify-center">
              <Gift className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-white">2. Order Food Delivery</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              Earn bonus points when you order hot trout specialties and meals from verified Swat restaurant partners.
            </p>
          </div>

          <div className="p-8 rounded-3xl bg-mountain-900 border border-mountain-800 space-y-4">
            <div className="w-12 h-12 rounded-2xl bg-amber-500/20 text-amber-400 border border-amber-500/30 flex items-center justify-center">
              <Sparkles className="w-6 h-6" />
            </div>
            <h3 className="text-xl font-bold text-white">3. Book Kalam 4x4 Tours</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              Mountain expeditions to Kalam and Mahodand Lake earn premium points that can be redeemed for hotel stays.
            </p>
          </div>
        </div>

        {/* CTA */}
        <CTASection
          title="Start Earning Swat Points Today"
          subtitle="Download the Android app to view your loyalty balance and redeem current promo vouchers."
          primaryCtaText="Download Android App"
          primaryCtaLink="/download"
          secondaryCtaText="View Promo Codes"
          secondaryCtaLink="/offers"
        />
      </div>
    </div>
  );
}
