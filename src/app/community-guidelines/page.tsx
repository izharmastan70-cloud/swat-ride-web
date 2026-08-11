'use client';

import React from 'react';
import Link from 'next/link';
import { ShieldCheck, Users, Heart, AlertCircle } from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';

export default function CommunityGuidelinesPage() {
  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Legal & Privacy', href: '/community-guidelines' },
            { label: 'SWAT RIDE Community Guidelines' },
          ]}
        />

        <div className="p-4 rounded-2xl bg-amber-950/80 border border-amber-500/40 text-xs text-amber-200 flex items-start gap-3 mb-8">
          <AlertCircle className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
          <div>
            <span className="font-bold uppercase tracking-wider block text-white">
              LEGAL REVIEW NOTICE
            </span>
            <span>
              These community guidelines require formal review by certified legal counsel in Khyber Pakhtunkhwa, Pakistan prior to formal commercial launch.
            </span>
          </div>
        </div>

        <div className="space-y-6 mb-12">
          <h1 className="text-4xl font-black text-white tracking-tight">
            SWAT RIDE Community Guidelines
          </h1>
          <p className="text-sm text-mountain-400">
            Last Updated: August 11, 2026 • Mutual Respect & Swati Hospitality
          </p>
        </div>

        <div className="prose prose-invert prose-emerald max-w-none space-y-8 text-mountain-200 text-sm leading-relaxed">
          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">1. Mutual Respect & Pashtun Hospitality</h2>
            <p>
              SWAT RIDE is built upon the timeless traditions of mutual respect, dignity, and Pashtun hospitality across Swat Valley. We expect all riders, drivers, parents, restaurant partners, food riders, and tour guides to treat each other with kindness and cultural courtesy.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">2. Safety First & Zero Harassment Policy</h2>
            <p>
              We maintain zero tolerance for verbal abuse, physical harassment, dangerous driving, or discrimination. Any verified violation results in immediate profile suspension and report to regional safety authorities.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">3. Property & Vehicle Care</h2>
            <p>
              Passengers must respect partner vehicles and hotel properties. Keep vehicles clean and refrain from carrying prohibited items or hazardous substances during normal rides or 4x4 Kalam tours.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">4. Reporting Violations</h2>
            <p>
              If you witness or experience any behavior that violates these community standards, report it immediately through our Safety & SOS Center or public feedback ticket desk.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
