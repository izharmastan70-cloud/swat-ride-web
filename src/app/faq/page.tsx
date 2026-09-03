'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { HelpCircle, ChevronDown, ChevronUp, Search, ArrowRight } from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { HELP_ARTICLES, HELP_CATEGORIES } from '@/data/help';
import { translateText } from '@/i18n/dictionaries';
import { cn } from '@/lib/utils';

export default function FAQPage() {
  const [openFaq, setOpenFaq] = useState<string | null>('sos-how-it-works');

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Support & Help', href: '/help' },
            { label: 'Frequently Asked Questions (FAQ)' },
          ]}
        />

        <SectionHeader
          badge="SWAT RIDE FAQ"
          title="Frequently Asked Questions"
          subtitle="Everything you need to know about upfront fare estimates, driver onboarding, food delivery thermal bags, student school transport, and Kalam 4x4 tours."
        />

        <div className="space-y-4 mb-16">
          {HELP_ARTICLES.map((article) => {
            const isOpen = openFaq === article.id;
            const titleEn = translateText(article.title, 'en');
            const summaryEn = translateText(article.summary, 'en');
            const contentEn = translateText(article.content, 'en');

            return (
              <div
                key={article.id}
                className="rounded-2xl bg-mountain-900/80 border border-mountain-800 overflow-hidden transition-all"
              >
                <button
                  onClick={() => setOpenFaq(isOpen ? null : article.id)}
                  className="w-full flex items-center justify-between p-6 text-left focus:outline-none"
                  aria-expanded={isOpen}
                >
                  <div className="pr-4">
                    <span className="text-base sm:text-lg font-bold text-white block">
                      {titleEn}
                    </span>
                    <span className="text-xs text-mountain-400 mt-1 block">{summaryEn}</span>
                  </div>
                  {isOpen ? (
                    <ChevronUp className="w-5 h-5 text-swat-400 shrink-0" />
                  ) : (
                    <ChevronDown className="w-5 h-5 text-mountain-400 shrink-0" />
                  )}
                </button>

                {isOpen && (
                  <div className="px-6 pb-6 text-sm text-mountain-300 leading-relaxed border-t border-mountain-800/60 pt-4 space-y-4">
                    <p>{contentEn}</p>
                    <div className="flex items-center justify-between pt-2 border-t border-mountain-800/40 text-[11px] text-mountain-400">
                      <span>Last updated: {article.lastUpdated}</span>
                      <span className="text-swat-400 font-semibold uppercase">
                        Category: {article.categoryId}
                      </span>
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>

        <div className="p-8 rounded-3xl bg-mountain-900 border border-mountain-800 text-center space-y-4">
          <h3 className="text-2xl font-bold text-white">Need More Specific Guidance?</h3>
          <p className="text-sm text-mountain-300 max-w-lg mx-auto">
            Our 18-Category Help Center includes searchable guides for drivers, restaurant partners, parents, and tour guides.
          </p>
          <div className="flex flex-wrap justify-center gap-4 pt-2">
            <Link
              href="/help"
              className="px-6 py-3 rounded-xl bg-swat-600 hover:bg-swat-500 text-white text-sm font-bold transition-all"
            >
              Visit Full Help Center
            </Link>
            <Link
              href="/help/videos"
              className="px-6 py-3 rounded-xl bg-white/10 hover:bg-white/15 text-white text-sm font-semibold border border-white/15 transition-all"
            >
              Watch Video Tutorials
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
