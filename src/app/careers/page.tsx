'use client';

import React from 'react';
import Link from 'next/link';
import {
  Briefcase,
  MapPin,
  CheckCircle2,
  ArrowRight,
  Send,
  Users,
  Award,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { CTASection } from '@/components/common/CTASection';

const OPEN_POSITIONS = [
  {
    title: 'Regional Fleet Verification Specialist',
    location: 'Mingora Office, Swat',
    department: 'Operations & Safety',
    type: 'Full-Time',
  },
  {
    title: 'Pashto & Urdu Customer Support Representative',
    location: 'Mingora Hub, Swat',
    department: 'Customer Experience',
    type: 'Full-Time',
  },
  {
    title: 'Swat Tourism & Expedition Coordinator',
    location: 'Mingora / Kalam Hub',
    department: 'Tours & Partnerships',
    type: 'Full-Time',
  },
];

export default function CareersPage() {
  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Company', href: '/about' },
            { label: 'Careers in Mingora & Swat' },
          ]}
        />

        {/* Hero */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-6">
          <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-swat-950/80 border border-swat-500/40 text-xs font-semibold text-swat-300">
            <Briefcase className="w-4 h-4 text-swat-400" />
            <span>SWAT RIDE • Regional Careers</span>
          </span>

          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            Build Swat’s Future Mobility Ecosystem
          </h1>

          <p className="text-base text-mountain-300 leading-relaxed">
            Join our dedicated engineering, operations, and support team in Mingora. We are looking for passionate individuals who care about safety, community trust, and Khyber Pakhtunkhwa tourism.
          </p>
        </div>

        {/* Open Positions Grid */}
        <div className="max-w-4xl mx-auto space-y-4 mb-20">
          <h2 className="text-xl font-bold text-white mb-6">Current Openings in Swat</h2>

          {OPEN_POSITIONS.map((pos, idx) => (
            <div
              key={idx}
              className="p-6 rounded-2xl bg-mountain-900 border border-mountain-800 hover:border-swat-500/40 transition-all flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4"
            >
              <div>
                <span className="text-xs font-bold uppercase text-swat-400">
                  {pos.department}
                </span>
                <h3 className="text-lg font-bold text-white mt-1">{pos.title}</h3>
                <div className="flex items-center gap-4 mt-2 text-xs text-mountain-400">
                  <span className="flex items-center gap-1">
                    <MapPin className="w-3.5 h-3.5" />
                    <span>{pos.location}</span>
                  </span>
                  <span>•</span>
                  <span>{pos.type}</span>
                </div>
              </div>

              <Link
                href="/contact"
                className="px-5 py-2.5 rounded-xl bg-mountain-800 hover:bg-swat-600 text-white text-xs font-bold transition-all shrink-0"
              >
                Apply via Support Desk
              </Link>
            </div>
          ))}
        </div>

        {/* Why Work With Us */}
        <div className="p-8 sm:p-12 rounded-3xl bg-mountain-900/80 border border-mountain-800 mb-20 text-center space-y-4 max-w-4xl mx-auto">
          <Award className="w-10 h-10 text-swat-400 mx-auto" />
          <h3 className="text-2xl font-bold text-white">Equal Opportunity Regional Employer</h3>
          <p className="text-sm text-mountain-300 max-w-xl mx-auto leading-relaxed">
            SWAT RIDE is proud to be an equal opportunity employer rooted in Khyber Pakhtunkhwa. We value integrity, multilingual proficiency (Pashto, Urdu, English), and commitment to public safety.
          </p>
        </div>

        <CTASection />
      </div>
    </div>
  );
}
