'use client';

import React from 'react';
import Link from 'next/link';
import { FileText, AlertCircle, ShieldCheck } from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';

export default function TermsOfServicePage() {
  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Legal & Privacy', href: '/terms' },
            { label: 'Terms of Service' },
          ]}
        />

        <div className="p-4 rounded-2xl bg-amber-950/80 border border-amber-500/40 text-xs text-amber-200 flex items-start gap-3 mb-8">
          <AlertCircle className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
          <div>
            <span className="font-bold uppercase tracking-wider block text-white">
              LEGAL REVIEW NOTICE
            </span>
            <span>
              This terms of service document requires formal legal review by certified counsel in Khyber Pakhtunkhwa, Pakistan prior to formal commercial launch.
            </span>
          </div>
        </div>

        <div className="space-y-6 mb-12">
          <h1 className="text-4xl font-black text-white tracking-tight">
            SWAT RIDE Terms of Service
          </h1>
          <p className="text-sm text-mountain-400">
            Last Updated: August 11, 2026 • Governing Law: Khyber Pakhtunkhwa, Pakistan
          </p>
        </div>

        <div className="prose prose-invert prose-emerald max-w-none space-y-8 text-mountain-200 text-sm leading-relaxed">
          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">1. Acceptance of Terms</h2>
            <p>
              By downloading, registering, or accessing the SWAT RIDE mobility and service ecosystem in Swat, Khyber Pakhtunkhwa, you agree to be bound by these Terms of Service. If you do not agree, do not use the application.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">2. Transparent Upfront Fare Estimates</h2>
            <p>
              SWAT RIDE displays upfront fare estimates before ride confirmation based on shortest accessible distance and standard regional tariffs. While we strive for absolute accuracy, significant route deviations requested by the passenger or extreme road blockages may adjust the final fare according to municipal rules.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">3. Partner Role Rules & Earnings Disclaimer</h2>
            <p>
              Drivers, restaurant partners, food riders, cargo drivers, student drivers, hotel partners, and tour guides operate as independent service partners. <strong className="text-white">SWAT RIDE does not guarantee fixed earnings or guaranteed order volumes.</strong> All partners must maintain clean security backgrounds and valid Pakistani CNIC documentation.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">4. Emergency SOS & Limitation of Liability</h2>
            <p>
              The SWAT RIDE SOS emergency button connects users to family Trusted Contacts and our Mingora Safety Desk. SWAT RIDE is not a law enforcement agency and makes no impossible claims of guaranteed physical rescue, but coordinates actively with local emergency responders in Swat.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">5. Governing Law & Dispute Resolution</h2>
            <p>
              These Terms shall be governed by and construed in accordance with the laws of Khyber Pakhtunkhwa and the Islamic Republic of Pakistan. Any dispute shall be resolved through amicable mediation or the competent courts of Mingora, District Swat.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
