'use client';

import React from 'react';
import Link from 'next/link';
import { Download, ArrowRight, ShieldCheck, Star } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface CTASectionProps {
  title?: string;
  subtitle?: string;
  primaryCtaText?: string;
  primaryCtaLink?: string;
  secondaryCtaText?: string;
  secondaryCtaLink?: string;
  className?: string;
}

export const CTASection: React.FC<CTASectionProps> = ({
  title = 'Ready to Experience Swat’s Most Trusted Mobility Platform?',
  subtitle = 'Download the SWAT RIDE app today for upfront fare estimates, verified local drivers, hot food delivery, and 4x4 Kalam mountain tours.',
  primaryCtaText = 'Download Android App',
  primaryCtaLink = '/download',
  secondaryCtaText = 'Explore Partner Roles',
  secondaryCtaLink = '/driver',
  className,
}) => {
  return (
    <section className={cn('relative py-16 sm:py-24 overflow-hidden', className)}>
      {/* Ambient background glow */}
      <div className="absolute inset-0 bg-gradient-to-r from-swat-900/60 via-mountain-900 to-swat-950/80 border-y border-white/10" />
      <div className="absolute -top-40 -left-40 w-96 h-96 rounded-full bg-swat-600/10 blur-3xl" />
      <div className="absolute -bottom-40 -right-40 w-96 h-96 rounded-full bg-amber-500/10 blur-3xl" />

      <div className="relative max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
        {/* Top trust badge */}
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-white/10 border border-white/15 text-xs font-semibold text-swat-300 mb-6 backdrop-blur-md">
          <ShieldCheck className="w-4 h-4 text-swat-400" />
          <span>Verified Security • Transparent Upfront Fares • Swat, KPK</span>
        </div>

        <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white tracking-tight leading-tight max-w-3xl mx-auto">
          {title}
        </h2>

        <p className="mt-4 text-base sm:text-lg text-mountain-300 max-w-2xl mx-auto leading-relaxed">
          {subtitle}
        </p>

        {/* Buttons */}
        <div className="mt-8 flex flex-col sm:flex-row items-center justify-center gap-4">
          <Link
            href={primaryCtaLink}
            className="inline-flex items-center justify-center gap-2.5 px-8 py-4 rounded-2xl bg-swat-600 hover:bg-swat-500 text-white font-bold text-base shadow-lg shadow-swat-600/40 hover:shadow-swat-500/60 hover:-translate-y-0.5 transition-all duration-200 w-full sm:w-auto"
          >
            <Download className="w-5 h-5" />
            <span>{primaryCtaText}</span>
          </Link>

          <Link
            href={secondaryCtaLink}
            className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl bg-white/10 hover:bg-white/15 text-white font-semibold text-base border border-white/15 backdrop-blur-md hover:-translate-y-0.5 transition-all duration-200 w-full sm:w-auto"
          >
            <span>{secondaryCtaText}</span>
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>

        {/* Bottom regional disclaimer note */}
        <p className="mt-6 text-xs text-mountain-400">
          Available on Android smartphones • Proudly engineered for Mingora, Saidu Sharif & Swat Valley
        </p>
      </div>
    </section>
  );
};
