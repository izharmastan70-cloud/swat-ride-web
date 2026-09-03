'use client';

import React from 'react';
import Link from 'next/link';
import { Car, ShieldAlert, Heart, ArrowUpRight, Phone, Mail, MapPin } from 'lucide-react';
import { FOOTER_LINKS } from '@/data/navigation';
import { Locale } from '@/types';
import { translateText } from '@/i18n/dictionaries';
import { cn } from '@/lib/utils';

export interface FooterProps {
  locale?: Locale;
}

export const Footer: React.FC<FooterProps> = ({ locale = 'en' }) => {
  const year = new Date().getFullYear();

  return (
    <footer className="relative bg-mountain-950 border-t border-white/10 text-mountain-300 overflow-hidden">
      {/* Top Banner: Emergency SOS & Regional Trust */}
      <div className="border-b border-mountain-800 bg-mountain-900/40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 text-center sm:text-left">
            <div className="flex items-center gap-3">
              <span className="flex items-center justify-center w-8 h-8 rounded-lg bg-red-600/20 text-red-400 border border-red-500/30">
                <ShieldAlert className="w-4 h-4" />
              </span>
              <div>
                <p className="text-xs font-bold text-white uppercase tracking-wider">
                  24/7 Verified Emergency SOS & Safety Monitoring
                </p>
                <p className="text-[11px] text-mountain-400">
                  Strictly adheres to KPK privacy laws • No unverified device monitoring
                </p>
              </div>
            </div>

            <Link
              href="/safety"
              className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg bg-red-600/20 hover:bg-red-600/40 text-red-300 border border-red-500/40 text-xs font-semibold transition-colors"
            >
              <span>Safety Command Center</span>
              <ArrowUpRight className="w-3.5 h-3.5" />
            </Link>
          </div>
        </div>
      </div>

      {/* Main Footer Content */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12 sm:py-16">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-10">
          {/* Col 1: Brand Info & KPK Location */}
          <div className="lg:col-span-2 space-y-4">
            <Link href="/" className="inline-flex items-center gap-2.5">
              <img
                src="/logo.jpg"
                alt="SWAT RIDE Official Logo"
                className="w-9 h-9 rounded-xl object-cover shadow-glow-emerald border border-white/20"
              />
              <span className="text-2xl font-black tracking-tight text-white">
                SWAT RIDE
              </span>
            </Link>

            <p className="text-sm text-mountain-400 leading-relaxed max-w-sm">
              Your Trusted Premium Mobility & Ecosystem in Swat, Khyber Pakhtunkhwa, Pakistan. Connecting Mingora, Saidu Sharif, Bahrain, Kalam, and Malam Jabba with upfront fare estimates and verified local drivers.
            </p>

            <div className="pt-2 space-y-2 text-xs text-mountain-400">
              <div className="flex items-center gap-2">
                <MapPin className="w-4 h-4 text-swat-400 shrink-0" />
                <span>Headquarters: Central Mingora, Swat, KPK, Pakistan</span>
              </div>
              <div className="flex items-center gap-2">
                <Mail className="w-4 h-4 text-swat-400 shrink-0" />
                <span>support@swatride.pk</span>
              </div>
              <div className="flex items-center gap-2">
                <Phone className="w-4 h-4 text-swat-400 shrink-0" />
                <span>0300-SWATRIDE (Local Swat Support Line)</span>
              </div>
            </div>
          </div>

          {/* Col 2: Services */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-white mb-4">
              Core Services
            </h4>
            <ul className="space-y-2.5 text-sm">
              {FOOTER_LINKS.services.map((item, idx) => (
                <li key={idx}>
                  <Link
                    href={item.href}
                    className="text-mountain-300 hover:text-swat-400 transition-colors"
                  >
                    {translateText(item.label, locale)}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Col 3: Partners & Roles */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-white mb-4">
              Partner With Us
            </h4>
            <ul className="space-y-2.5 text-sm">
              {FOOTER_LINKS.partners.map((item, idx) => (
                <li key={idx}>
                  <Link
                    href={item.href}
                    className="text-mountain-300 hover:text-swat-400 transition-colors"
                  >
                    {translateText(item.label, locale)}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Col 4: Help, Safety & Legal */}
          <div>
            <h4 className="text-xs font-bold uppercase tracking-wider text-white mb-4">
              Support & Legal
            </h4>
            <ul className="space-y-2.5 text-sm">
              {FOOTER_LINKS.supportAndSafety.map((item, idx) => (
                <li key={idx}>
                  <Link
                    href={item.href}
                    className="text-mountain-300 hover:text-swat-400 transition-colors"
                  >
                    {translateText(item.label, locale)}
                  </Link>
                </li>
              ))}
              {FOOTER_LINKS.legalAndCompany.map((item, idx) => (
                <li key={idx}>
                  <Link
                    href={item.href}
                    className="text-mountain-400 hover:text-white transition-colors text-xs"
                  >
                    {translateText(item.label, locale)}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        </div>
      </div>

      {/* Bottom Legal & Attribution Line */}
      <div className="border-t border-mountain-800/80 bg-mountain-950/80">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <div className="flex flex-col sm:flex-row items-center justify-between gap-4 text-xs text-mountain-400">
            <p>
              © {year} SWAT RIDE Mobility Ecosystem. All rights reserved across Swat & KPK.
            </p>

            <div className="flex items-center gap-4 text-mountain-400">
              <Link href="/privacy" className="hover:text-white transition-colors">
                Privacy Policy
              </Link>
              <span>•</span>
              <Link href="/terms" className="hover:text-white transition-colors">
                Terms of Service
              </Link>
              <span>•</span>
              <Link href="/sitemap.xml" className="hover:text-white transition-colors">
                Sitemap
              </Link>
            </div>
          </div>
        </div>
      </div>
    </footer>
  );
};
