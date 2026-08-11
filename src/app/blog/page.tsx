'use client';

import React, { useState, useMemo } from 'react';
import Link from 'next/link';
import {
  BookOpen,
  Calendar,
  Clock,
  User,
  Search,
  ArrowRight,
  Tag,
  Share2,
  CheckCircle2,
  Filter,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SearchBar } from '@/components/ui/SearchBar';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { BLOG_ARTICLES, BLOG_CATEGORIES } from '@/data/blog';
import { cn } from '@/lib/utils';

export default function BlogListingPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('All');

  const filteredArticles = useMemo(() => {
    return BLOG_ARTICLES.filter((article) => {
      const matchesCategory =
        selectedCategory === 'All' ? true : article.category === selectedCategory;
      const q = searchQuery.toLowerCase().trim();
      if (!q) return matchesCategory;

      const titleMatches = article.title.toLowerCase().includes(q);
      const subtitleMatches = article.subtitle.toLowerCase().includes(q);
      const excerptMatches = article.excerpt.toLowerCase().includes(q);
      const tagMatches = article.tags.some((tag) => tag.toLowerCase().includes(q));

      return matchesCategory && (titleMatches || subtitleMatches || excerptMatches || tagMatches);
    });
  }, [searchQuery, selectedCategory]);

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Resources', href: '/blog' },
            { label: 'Swat Travel & Mobility Blog' },
          ]}
        />

        {/* Hero Banner */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-6">
          <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-swat-950/80 border border-swat-500/40 text-xs font-semibold text-swat-300">
            <BookOpen className="w-4 h-4 text-swat-400" />
            <span>SWAT RIDE • Verified Knowledge Desk</span>
          </span>

          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            Swat Travel Guides, Tips & Platform Updates
          </h1>

          <p className="text-base text-mountain-300 leading-relaxed">
            Human-authored, verified guides covering Kalam mountain road routes, school transport safety protocols, fuel efficiency for drivers, and authentic Swati culinary destinations.
          </p>

          <div className="max-w-xl mx-auto pt-2">
            <SearchBar
              value={searchQuery}
              onChange={setSearchQuery}
              placeholder="Search guides (e.g. Kalam, Trout, School Safety, 4x4)..."
            />
          </div>

          {/* Category Filter Pills */}
          <div className="flex flex-wrap items-center justify-center gap-2 pt-2">
            {BLOG_CATEGORIES.map((cat) => {
              const isSelected = selectedCategory === cat;
              return (
                <button
                  key={cat}
                  onClick={() => setSelectedCategory(cat)}
                  className={cn(
                    'px-3.5 py-1.5 rounded-full text-xs font-bold transition-all',
                    isSelected
                      ? 'bg-swat-600 text-white shadow-md'
                      : 'bg-mountain-900 border border-mountain-800 text-mountain-300 hover:text-white'
                  )}
                >
                  {cat}
                </button>
              );
            })}
          </div>
        </div>

        {/* Articles Grid */}
        <div className="mb-20">
          <div className="flex items-center justify-between border-b border-mountain-800 pb-4 mb-8">
            <h2 className="text-xl font-bold text-white">
              {searchQuery
                ? `Search Results for "${searchQuery}" (${filteredArticles.length})`
                : selectedCategory === 'All'
                ? `All Published Articles (${filteredArticles.length})`
                : `${selectedCategory} Guides (${filteredArticles.length})`}
            </h2>
            <span className="text-xs text-mountain-400">
              CMS Workflow: Published & Human-Verified
            </span>
          </div>

          {filteredArticles.length === 0 && (
            <div className="p-12 text-center rounded-2xl bg-mountain-900/40 border border-mountain-800 space-y-3">
              <BookOpen className="w-10 h-10 text-mountain-500 mx-auto" />
              <h4 className="text-base font-bold text-white">No Matching Articles</h4>
              <p className="text-xs text-mountain-400">
                We couldn’t find any guide matching &ldquo;{searchQuery}&rdquo;.
              </p>
              <button
                onClick={() => {
                  setSearchQuery('');
                  setSelectedCategory('All');
                }}
                className="mt-2 px-5 py-2 rounded-xl bg-swat-600 text-white text-xs font-bold"
              >
                Reset Filters
              </button>
            </div>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {filteredArticles.map((article) => (
              <Link
                key={article.id}
                href={`/blog/${article.slug}`}
                className="group flex flex-col justify-between rounded-2xl bg-mountain-900 border border-mountain-800 hover:border-swat-500/50 overflow-hidden shadow-glass-sm transition-all duration-300"
              >
                <div className="h-48 bg-mountain-800 relative overflow-hidden">
                  <img
                    src={article.coverImage}
                    alt={article.title}
                    className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                  <span className="absolute top-3 left-3 px-2.5 py-1 text-[11px] font-bold uppercase rounded-md bg-swat-950/80 text-swat-300 border border-swat-500/30 backdrop-blur-md">
                    {article.category}
                  </span>
                </div>

                <div className="p-6 flex-1 flex flex-col justify-between space-y-4">
                  <div>
                    <h3 className="text-lg font-bold text-white group-hover:text-swat-300 transition-colors line-clamp-2">
                      {article.title}
                    </h3>
                    <p className="text-xs text-mountain-300 mt-2 line-clamp-3 leading-relaxed">
                      {article.excerpt}
                    </p>

                    <div className="flex flex-wrap gap-1.5 mt-4">
                      {article.tags.map((tag, i) => (
                        <span
                          key={i}
                          className="px-2 py-0.5 text-[10px] rounded bg-mountain-950 text-mountain-400 border border-mountain-800"
                        >
                          #{tag}
                        </span>
                      ))}
                    </div>
                  </div>

                  <div className="pt-4 border-t border-mountain-800/80 flex items-center justify-between text-xs text-mountain-400">
                    <div className="flex items-center gap-2">
                      <img
                        src={article.author.avatarUrl}
                        alt={article.author.name}
                        className="w-5 h-5 rounded-full object-cover"
                      />
                      <span>{article.author.name}</span>
                    </div>
                    <span>{article.readTime}</span>
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </div>

        {/* CMS Workflow Banner */}
        <div className="p-8 rounded-3xl bg-gradient-to-r from-mountain-900 via-mountain-950 to-swat-950/40 border border-mountain-800 text-center space-y-3">
          <h3 className="text-xl font-bold text-white">SWAT RIDE CMS Editorial Standard</h3>
          <p className="text-xs text-mountain-400 max-w-xl mx-auto leading-relaxed">
            Our content team publishes verified travel guides approximately every 2 days. Every article is reviewed by local Swat travel specialists to ensure road condition accuracy and zero low-quality AI spam.
          </p>
        </div>
      </div>
    </div>
  );
}
