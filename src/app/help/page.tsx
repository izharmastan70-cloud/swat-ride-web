'use client';

import React, { useState, useMemo } from 'react';
import Link from 'next/link';
import {
  HelpCircle,
  Search,
  BookOpen,
  ChevronRight,
  ChevronDown,
  ChevronUp,
  Video,
  FileText,
  MessageSquare,
  ShieldAlert,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SearchBar } from '@/components/ui/SearchBar';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { HELP_CATEGORIES, HELP_ARTICLES } from '@/data/help';
import { translateText } from '@/i18n/dictionaries';
import { cn } from '@/lib/utils';

export default function HelpCenterPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string | null>(null);
  const [expandedArticleId, setExpandedArticleId] = useState<string | null>('sos-how-it-works');

  // Filter articles by search string and selected category
  const filteredArticles = useMemo(() => {
    return HELP_ARTICLES.filter((article) => {
      const matchesCategory = selectedCategory ? article.categoryId === selectedCategory : true;
      const q = searchQuery.toLowerCase().trim();
      if (!q) return matchesCategory;

      const titleEn = translateText(article.title, 'en').toLowerCase();
      const titleUr = translateText(article.title, 'ur').toLowerCase();
      const summaryEn = translateText(article.summary, 'en').toLowerCase();
      const contentEn = translateText(article.content, 'en').toLowerCase();

      const matchesSearch =
        titleEn.includes(q) ||
        titleUr.includes(q) ||
        summaryEn.includes(q) ||
        contentEn.includes(q);

      return matchesCategory && matchesSearch;
    });
  }, [searchQuery, selectedCategory]);

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Support & Help', href: '/help' },
            { label: 'Help & Knowledge Center' },
          ]}
        />

        {/* Hero & Search Header */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-6">
          <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-swat-950/80 border border-swat-500/40 text-xs font-semibold text-swat-300">
            <HelpCircle className="w-4 h-4 text-swat-400" />
            <span>18 Searchable Support Categories</span>
          </span>

          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            How Can We Help You Today?
          </h1>

          <p className="text-base text-mountain-300 leading-relaxed">
            Search our knowledge base regarding rides, driver verification, food delivery thermal bags, student transport safety, and 4x4 Kalam tourism.
          </p>

          {/* Interactive Search Bar */}
          <div className="max-w-xl mx-auto pt-2">
            <SearchBar
              value={searchQuery}
              onChange={setSearchQuery}
              placeholder="Search fares, SOS, driver documents, food delivery..."
            />
          </div>

          <div className="flex flex-wrap items-center justify-center gap-3 pt-2 text-xs">
            <Link
              href="/help/videos"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-swat-600/20 text-swat-300 border border-swat-500/30 hover:bg-swat-600/40 transition-colors font-semibold"
            >
              <Video className="w-3.5 h-3.5" />
              <span>Video Tutorials</span>
            </Link>
            <Link
              href="/contact"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-white/10 text-white border border-white/15 hover:bg-white/15 transition-colors font-semibold"
            >
              <MessageSquare className="w-3.5 h-3.5" />
              <span>Submit Ticket / Feedback</span>
            </Link>
            <Link
              href="/safety"
              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-red-600/20 text-red-300 border border-red-500/40 hover:bg-red-600/30 transition-colors font-semibold"
            >
              <ShieldAlert className="w-3.5 h-3.5" />
              <span>Safety & SOS</span>
            </Link>
          </div>
        </div>

        {/* 18 Help Categories Grid */}
        <div className="mb-16">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-xl font-extrabold text-white">Browse by Service Category (18)</h2>
            {selectedCategory && (
              <button
                onClick={() => setSelectedCategory(null)}
                className="text-xs font-bold text-swat-400 hover:text-swat-300 transition-colors"
              >
                Clear Category Filter ({selectedCategory})
              </button>
            )}
          </div>

          <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3">
            {HELP_CATEGORIES.map((cat) => {
              const isSelected = selectedCategory === cat.id;
              const titleText = translateText(cat.title, 'en');
              return (
                <button
                  key={cat.id}
                  onClick={() => setSelectedCategory(isSelected ? null : cat.id)}
                  className={cn(
                    'p-4 rounded-2xl border text-left transition-all duration-200 flex flex-col justify-between h-28',
                    isSelected
                      ? 'bg-swat-950/80 border-swat-500 shadow-glow-emerald text-white'
                      : 'bg-mountain-900/80 border-mountain-800 hover:border-swat-500/40 text-mountain-200'
                  )}
                >
                  <span className="text-xs font-bold truncate block">{titleText}</span>
                  <span className="text-[10px] text-mountain-400">
                    {cat.articleCount} articles
                  </span>
                </button>
              );
            })}
          </div>
        </div>

        {/* Search & Category Filtered Articles Accordion */}
        <div className="max-w-4xl mx-auto space-y-4 mb-20">
          <div className="flex items-center justify-between border-b border-mountain-800 pb-3">
            <h3 className="text-lg font-bold text-white">
              {searchQuery
                ? `Search Results for "${searchQuery}" (${filteredArticles.length})`
                : selectedCategory
                ? `Category: ${selectedCategory.toUpperCase()} (${filteredArticles.length})`
                : 'Popular Support Articles'}
            </h3>
            <span className="text-xs text-mountain-400 font-medium">Click any question to expand</span>
          </div>

          {filteredArticles.length === 0 && (
            <div className="p-12 text-center rounded-2xl bg-mountain-900/40 border border-mountain-800 space-y-3">
              <HelpCircle className="w-10 h-10 text-mountain-500 mx-auto" />
              <h4 className="text-base font-bold text-white">No Matching Articles Found</h4>
              <p className="text-xs text-mountain-400 max-w-md mx-auto">
                We couldn’t find an article matching &ldquo;{searchQuery}&rdquo;. Try another search keyword or submit a support ticket below.
              </p>
              <Link
                href="/contact"
                className="inline-block mt-2 px-5 py-2 rounded-xl bg-swat-600 text-white text-xs font-bold"
              >
                Contact Support Desk
              </Link>
            </div>
          )}

          {filteredArticles.map((article) => {
            const isOpen = expandedArticleId === article.id;
            const titleEn = translateText(article.title, 'en');
            const summaryEn = translateText(article.summary, 'en');
            const contentEn = translateText(article.content, 'en');

            return (
              <div
                key={article.id}
                className="rounded-2xl bg-mountain-900/80 border border-mountain-800 overflow-hidden transition-all"
              >
                <button
                  onClick={() => setExpandedArticleId(isOpen ? null : article.id)}
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

        {/* Support Entry Banner */}
        <div className="p-8 sm:p-12 rounded-3xl bg-gradient-to-r from-mountain-900 via-mountain-950 to-swat-950/40 border border-mountain-800 shadow-glass-lg flex flex-col sm:flex-row items-center justify-between gap-8">
          <div className="space-y-2 text-center sm:text-left">
            <h3 className="text-2xl font-bold text-white">Still Need Assistance?</h3>
            <p className="text-sm text-mountain-300 max-w-xl">
              Our Swat Customer Support Desk responds to complaints, technical issues, suggestions, and feedback promptly.
            </p>
          </div>
          <Link
            href="/contact"
            className="inline-flex items-center gap-2 px-8 py-4 rounded-2xl bg-swat-600 hover:bg-swat-500 text-white font-bold text-sm shadow-lg shadow-swat-600/30 transition-all shrink-0"
          >
            <span>Submit a Feedback Ticket</span>
            <ChevronRight className="w-4 h-4" />
          </Link>
        </div>
      </div>
    </div>
  );
}
