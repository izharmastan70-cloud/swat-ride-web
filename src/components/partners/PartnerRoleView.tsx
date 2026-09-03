'use client';

import React from 'react';
import Link from 'next/link';
import * as Icons from 'lucide-react';
import { PartnerRole } from '@/types';
import { translateText } from '@/i18n/dictionaries';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { CTASection } from '@/components/common/CTASection';
import { cn } from '@/lib/utils';

export interface PartnerRoleViewProps {
  role: PartnerRole;
}

export const PartnerRoleView: React.FC<PartnerRoleViewProps> = ({ role }) => {
  const IconComponent = (Icons as any)[role.iconName] || Icons.CheckCircle2;

  const getCategoryBadgeColor = (cat: string) => {
    switch (cat) {
      case 'driver':
        return 'bg-swat-600/20 text-swat-300 border-swat-500/30';
      case 'merchant':
        return 'bg-amber-500/20 text-amber-300 border-amber-500/30';
      case 'guardian':
        return 'bg-emerald-600/20 text-emerald-300 border-emerald-500/30';
      case 'guide':
        return 'bg-sky-500/20 text-sky-300 border-sky-500/30';
      default:
        return 'bg-mountain-800 text-mountain-300 border-mountain-700';
    }
  };

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Partners', href: '/driver' },
            { label: translateText(role.title, 'en') },
          ]}
        />

        {/* Hero Banner */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center mb-20">
          <div className="lg:col-span-8 space-y-6">
            <div className="flex flex-wrap items-center gap-2">
              <span
                className={cn(
                  'px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider border',
                  getCategoryBadgeColor(role.category)
                )}
              >
                SWAT RIDE • {role.category.toUpperCase()} PARTNER
              </span>
              <span className="px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-white/10 text-white border border-white/15">
                Swat District • KPK
              </span>
            </div>

            <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black text-white tracking-tight leading-tight">
              {translateText(role.title, 'en')}
            </h1>

            <p className="text-base sm:text-lg text-mountain-300 leading-relaxed max-w-3xl">
              {translateText(role.subtitle, 'en')}
            </p>

            {/* Earnings Disclaimer Note */}
            <div className="p-4 rounded-2xl bg-mountain-900 border border-mountain-700/60 text-xs text-amber-300 flex items-start gap-3 max-w-2xl">
              <Icons.AlertCircle className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
              <p className="leading-relaxed font-medium">
                {translateText(role.earningsDisclaimer, 'en')}
              </p>
            </div>

            <div className="flex flex-col sm:flex-row items-center gap-4 pt-2">
              <Link
                href="/download"
                className="inline-flex items-center justify-center gap-2.5 px-8 py-4 rounded-2xl bg-swat-600 hover:bg-swat-500 text-white font-bold text-base shadow-lg shadow-swat-600/30 transition-all w-full sm:w-auto"
              >
                <Icons.Download className="w-5 h-5" />
                <span>Apply in Android App</span>
              </Link>
              <Link
                href="/help"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl bg-white/10 hover:bg-white/15 text-white font-semibold text-base border border-white/15 transition-all w-full sm:w-auto"
              >
                <span>Partner Help & FAQ</span>
                <Icons.ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          {/* Right Icon Box */}
          <div className="lg:col-span-4 flex items-center justify-center">
            <div className="p-8 rounded-3xl bg-gradient-to-br from-mountain-900 via-mountain-950 to-swat-950/60 border border-mountain-800 shadow-glass-lg text-center space-y-4 w-full max-w-xs">
              <div className="w-20 h-20 rounded-2xl bg-swat-600/20 text-swat-400 border border-swat-500/30 flex items-center justify-center mx-auto">
                <IconComponent className="w-10 h-10" />
              </div>
              <h3 className="text-xl font-bold text-white">Swat Verified Network</h3>
              <p className="text-xs text-mountain-400">
                Mingora Regional Verification Office • Fast onboarding with transparent commission reporting
              </p>
            </div>
          </div>
        </div>

        {/* Benefits Grid */}
        <SectionHeader
          badge="Why Join Our Network"
          title="Key Advantages & Transparency"
          subtitle="Discover how our ecosystem supports your schedule, earnings tracking, and regional growth."
        />

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-20">
          {role.benefits.map((benefit, idx) => {
            const BenefitIcon = (Icons as any)[benefit.icon] || Icons.CheckCircle;
            return (
              <div
                key={idx}
                className="p-8 rounded-2xl bg-mountain-900/80 border border-mountain-800 hover:border-swat-500/40 transition-all space-y-4"
              >
                <div className="w-12 h-12 rounded-xl bg-swat-600/20 text-swat-400 border border-swat-500/30 flex items-center justify-center">
                  <BenefitIcon className="w-6 h-6" />
                </div>
                <h3 className="text-xl font-bold text-white">
                  {translateText(benefit.title, 'en')}
                </h3>
                <p className="text-sm text-mountain-300 leading-relaxed">
                  {translateText(benefit.description, 'en')}
                </p>
              </div>
            );
          })}
        </div>

        {/* Requirements Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 mb-20 items-center">
          <div className="lg:col-span-5 space-y-4">
            <span className="text-xs font-bold uppercase tracking-wider text-swat-400">
              Eligibility Checklist
            </span>
            <h2 className="text-3xl font-extrabold text-white tracking-tight">
              Requirements to Get Started
            </h2>
            <p className="text-sm text-mountain-300 leading-relaxed">
              We uphold strict community safety standards in Khyber Pakhtunkhwa. Prepare these documents for rapid verification at our Mingora center.
            </p>
          </div>

          <div className="lg:col-span-7">
            <div className="p-8 rounded-3xl bg-mountain-900 border border-mountain-800 space-y-4">
              {role.requirements.map((req, idx) => (
                <div key={idx} className="flex items-start gap-4">
                  <div className="p-1 rounded-full bg-swat-500/20 text-swat-400 shrink-0 mt-0.5">
                    <Icons.Check className="w-4 h-4" />
                  </div>
                  <p className="text-sm text-mountain-100 font-medium leading-relaxed">
                    {translateText(req, 'en')}
                  </p>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* 3 Step Onboarding Workflow */}
        <SectionHeader
          badge="Simple 3-Step Process"
          title="How to Register & Go Live"
          subtitle="From application submission to admin verification, get approved without delays."
        />

        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-20">
          {role.onboardingSteps.map((step, idx) => (
            <div
              key={idx}
              className="relative p-8 rounded-2xl bg-mountain-900/80 border border-mountain-800 flex flex-col justify-between"
            >
              <div className="flex items-center justify-between mb-6">
                <span className="text-2xl font-black text-swat-400 font-mono">
                  0{step.step}
                </span>
                <Icons.CheckCircle2 className="w-6 h-6 text-mountain-500" />
              </div>
              <div>
                <h3 className="text-lg font-bold text-white mb-2">
                  {translateText(step.title, 'en')}
                </h3>
                <p className="text-sm text-mountain-300 leading-relaxed">
                  {translateText(step.detail, 'en')}
                </p>
              </div>
            </div>
          ))}
        </div>

        {/* CTA Banner */}
        <CTASection
          title={`Ready to ${translateText(role.title, 'en')}?`}
          subtitle="Download the Android app today to submit your profile and join Swat’s trusted platform."
          primaryCtaText="Apply Now in App"
          primaryCtaLink="/download"
          secondaryCtaText="Contact Support Team"
          secondaryCtaLink="/contact"
        />
      </div>
    </div>
  );
};
