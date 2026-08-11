'use client';

import React, { useState, useMemo } from 'react';
import Link from 'next/link';
import {
  Video,
  Play,
  Clock,
  FileText,
  X,
  Search,
  ExternalLink,
  HelpCircle,
  Download,
  CheckCircle2,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SearchBar } from '@/components/ui/SearchBar';
import { Modal } from '@/components/ui/Modal';
import { VIDEO_TUTORIALS } from '@/data/videos';
import { VideoTutorial } from '@/types';
import { translateText } from '@/i18n/dictionaries';
import { cn } from '@/lib/utils';

export default function VideoTutorialCenterPage() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState<string>('All');
  const [activeVideoModal, setActiveVideoModal] = useState<VideoTutorial | null>(null);
  const [showTranscript, setShowTranscript] = useState(false);

  const categories = useMemo(() => {
    const set = new Set<string>(['All']);
    VIDEO_TUTORIALS.forEach((v) => set.add(v.category));
    return Array.from(set);
  }, []);

  const filteredVideos = useMemo(() => {
    return VIDEO_TUTORIALS.filter((v) => {
      const matchesCategory = selectedCategory === 'All' ? true : v.category === selectedCategory;
      const q = searchQuery.toLowerCase().trim();
      if (!q) return matchesCategory;

      const titleEn = translateText(v.title, 'en').toLowerCase();
      const descEn = translateText(v.description, 'en').toLowerCase();
      const transEn = translateText(v.transcript, 'en').toLowerCase();

      const matchesSearch =
        titleEn.includes(q) || descEn.includes(q) || transEn.includes(q);

      return matchesCategory && matchesSearch;
    });
  }, [searchQuery, selectedCategory]);

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Support & Help', href: '/help' },
            { label: 'How-To Video Tutorial Center' },
          ]}
        />

        {/* Hero Section */}
        <div className="text-center max-w-3xl mx-auto mb-16 space-y-6">
          <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-swat-950/80 border border-swat-500/40 text-xs font-semibold text-swat-300">
            <Video className="w-4 h-4 text-swat-400" />
            <span>SWAT RIDE • Video Tutorial Center</span>
          </span>

          <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight">
            Searchable How-To Video Tutorials
          </h1>

          <p className="text-base text-mountain-300 leading-relaxed">
            Watch step-by-step video guides covering upfront ride fares, driver onboarding, food delivery thermal bags, student school transit, and 4x4 Kalam tourism. Every video includes transcripts and caption support.
          </p>

          <div className="max-w-xl mx-auto pt-2">
            <SearchBar
              value={searchQuery}
              onChange={setSearchQuery}
              placeholder="Search video tutorials (e.g., upfront fare, SOS, cargo, driver)..."
            />
          </div>

          {/* Category Filter Pills */}
          <div className="flex flex-wrap items-center justify-center gap-2 pt-2">
            {categories.map((cat) => {
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

        {/* Video Cards Grid */}
        <div className="mb-20">
          <div className="flex items-center justify-between border-b border-mountain-800 pb-4 mb-8">
            <h2 className="text-xl font-bold text-white">
              {searchQuery
                ? `Results for "${searchQuery}" (${filteredVideos.length})`
                : selectedCategory === 'All'
                ? `All How-To Tutorials (${filteredVideos.length})`
                : `${selectedCategory} Tutorials (${filteredVideos.length})`}
            </h2>
            <span className="text-xs text-mountain-400">Click any video to open player</span>
          </div>

          {filteredVideos.length === 0 && (
            <div className="p-12 text-center rounded-2xl bg-mountain-900/40 border border-mountain-800 space-y-3">
              <Video className="w-10 h-10 text-mountain-500 mx-auto" />
              <h4 className="text-base font-bold text-white">No Matching Videos</h4>
              <p className="text-xs text-mountain-400">
                Try another search query or check out our written Help Center articles.
              </p>
              <Link
                href="/help"
                className="inline-block mt-2 px-5 py-2 rounded-xl bg-swat-600 text-white text-xs font-bold"
              >
                Go to Help Center
              </Link>
            </div>
          )}

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-8">
            {filteredVideos.map((item) => {
              const titleEn = translateText(item.title, 'en');
              const descEn = translateText(item.description, 'en');

              return (
                <div
                  key={item.id}
                  onClick={() => {
                    setActiveVideoModal(item);
                    setShowTranscript(false);
                  }}
                  className="group cursor-pointer rounded-2xl bg-mountain-900 border border-mountain-800 hover:border-swat-500/50 overflow-hidden shadow-glass-sm transition-all duration-300 flex flex-col justify-between"
                >
                  {/* Thumbnail with Play Icon Overlay */}
                  <div className="relative h-48 bg-mountain-800 overflow-hidden">
                    <img
                      src={item.thumbnailUrl}
                      alt={titleEn}
                      className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                    />
                    <div className="absolute inset-0 bg-mountain-950/40 flex items-center justify-center transition-colors group-hover:bg-mountain-950/20">
                      <div className="w-14 h-14 rounded-full bg-swat-600/90 text-white flex items-center justify-center shadow-lg transition-transform group-hover:scale-110">
                        <Play className="w-6 h-6 fill-white ml-0.5" />
                      </div>
                    </div>
                    <span className="absolute bottom-3 right-3 px-2 py-0.5 rounded bg-mountain-950/90 text-[11px] font-mono text-white">
                      {item.duration}
                    </span>
                    <span className="absolute top-3 left-3 px-2.5 py-0.5 rounded bg-swat-950/80 text-swat-300 border border-swat-500/30 text-[10px] font-bold uppercase">
                      {item.category}
                    </span>
                  </div>

                  {/* Title & Description */}
                  <div className="p-6 flex-1 flex flex-col justify-between space-y-4">
                    <div>
                      <h3 className="text-lg font-bold text-white group-hover:text-swat-300 transition-colors line-clamp-2">
                        {titleEn}
                      </h3>
                      <p className="text-xs text-mountain-300 mt-2 line-clamp-3 leading-relaxed">
                        {descEn}
                      </p>
                    </div>

                    <div className="pt-4 border-t border-mountain-800/80 flex items-center justify-between text-xs text-swat-400 font-semibold">
                      <span>Watch Tutorial & Transcript</span>
                      <ExternalLink className="w-3.5 h-3.5" />
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>

        {/* Lazy-Loaded Video Modal */}
        <Modal
          isOpen={!!activeVideoModal}
          onClose={() => setActiveVideoModal(null)}
          title={activeVideoModal ? translateText(activeVideoModal.title, 'en') : ''}
          maxWidth="xl"
        >
          {activeVideoModal && (
            <div className="space-y-6">
              {/* HTML5 Video Player (Lazy-Loaded only when modal is open) */}
              <div className="relative rounded-2xl overflow-hidden bg-black aspect-video">
                <video
                  controls
                  autoPlay
                  className="w-full h-full object-cover"
                  src={activeVideoModal.videoUrl}
                  poster={activeVideoModal.thumbnailUrl}
                >
                  Your browser does not support HTML5 video.
                </video>
              </div>

              {/* Description */}
              <div className="space-y-2">
                <div className="flex items-center justify-between text-xs text-mountain-400">
                  <span className="px-2.5 py-1 rounded bg-swat-950 text-swat-300 font-bold uppercase">
                    Category: {activeVideoModal.category}
                  </span>
                  <span>Duration: {activeVideoModal.duration}</span>
                </div>
                <p className="text-sm text-mountain-200 leading-relaxed">
                  {translateText(activeVideoModal.description, 'en')}
                </p>
              </div>

              {/* Transcript & Captions Toggle */}
              <div className="pt-4 border-t border-mountain-800">
                <div className="flex items-center justify-between mb-3">
                  <h4 className="text-xs font-bold uppercase tracking-wider text-white">
                    Video Transcript & Captions
                  </h4>
                  <button
                    onClick={() => setShowTranscript(!showTranscript)}
                    className="text-xs font-bold text-swat-400 hover:text-swat-300"
                  >
                    {showTranscript ? 'Hide Transcript' : 'Show Full Transcript'}
                  </button>
                </div>

                {showTranscript ? (
                  <div className="p-4 rounded-xl bg-mountain-950/80 border border-mountain-800 text-xs text-mountain-300 leading-relaxed space-y-2">
                    <p className="font-semibold text-white">English Transcript:</p>
                    <p>{translateText(activeVideoModal.transcript, 'en')}</p>
                    <p className="font-semibold text-white pt-2">Urdu Translation:</p>
                    <p className="font-nastaliq text-right text-sm">
                      {translateText(activeVideoModal.transcript, 'ur')}
                    </p>
                  </div>
                ) : (
                  <p className="text-xs text-mountain-400">
                    Click &ldquo;Show Full Transcript&rdquo; to read the English and Urdu script accompanying this tutorial.
                  </p>
                )}
              </div>

              {/* Related Help & Services Links */}
              <div className="pt-4 border-t border-mountain-800 flex flex-wrap items-center justify-between gap-4">
                {activeVideoModal.relatedServiceSlug && (
                  <Link
                    href={`/${activeVideoModal.relatedServiceSlug}`}
                    onClick={() => setActiveVideoModal(null)}
                    className="inline-flex items-center gap-1.5 text-xs font-semibold text-swat-400 hover:text-swat-300"
                  >
                    <span>Go to {activeVideoModal.relatedServiceSlug.toUpperCase()} Service</span>
                    <ExternalLink className="w-3.5 h-3.5" />
                  </Link>
                )}
                <Link
                  href="/help"
                  onClick={() => setActiveVideoModal(null)}
                  className="inline-flex items-center gap-1.5 text-xs font-semibold text-mountain-300 hover:text-white"
                >
                  <HelpCircle className="w-3.5 h-3.5" />
                  <span>Back to Help Center</span>
                </Link>
              </div>
            </div>
          )}
        </Modal>
      </div>
    </div>
  );
}
