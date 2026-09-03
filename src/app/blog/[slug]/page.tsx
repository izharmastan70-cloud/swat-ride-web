import React from 'react';
import { notFound } from 'next/navigation';
import Link from 'next/link';
import {
  Calendar,
  Clock,
  User,
  ArrowLeft,
  Share2,
  Tag,
  CheckCircle2,
  BookOpen,
} from 'lucide-react';
import { BLOG_ARTICLES } from '@/data/blog';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { CTASection } from '@/components/common/CTASection';
import { SchemaOrg } from '@/components/common/SchemaOrg';

interface BlogArticlePageProps {
  params: {
    slug: string;
  };
}

export async function generateStaticParams() {
  return BLOG_ARTICLES.map((article) => ({
    slug: article.slug,
  }));
}

export default function BlogArticleDetailPage({ params }: BlogArticlePageProps) {
  const article = BLOG_ARTICLES.find((a) => a.slug === params.slug);
  if (!article) return notFound();

  // Generate Article JSON-LD Schema
  const articleSchema = {
    headline: article.title,
    description: article.excerpt,
    image: article.coverImage,
    datePublished: article.publishedAt,
    dateModified: article.updatedAt,
    author: {
      '@type': 'Person',
      name: article.author.name,
      jobTitle: article.author.role,
    },
    publisher: {
      '@type': 'Organization',
      name: 'SWAT RIDE',
      logo: {
        '@type': 'ImageObject',
        url: 'https://swatride.pk/logo.png',
      },
    },
  };

  const relatedArticles = BLOG_ARTICLES.filter(
    (a) => a.id !== article.id && a.category === article.category
  ).slice(0, 2);

  return (
    <div className="relative py-12 sm:py-16">
      <SchemaOrg type="Article" data={articleSchema} />

      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Blog & Guides', href: '/blog' },
            { label: article.category, href: '/blog' },
            { label: article.title },
          ]}
        />

        {/* Article Header */}
        <div className="space-y-6 mb-10">
          <div className="flex flex-wrap items-center gap-2">
            <span className="px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-swat-600/20 text-swat-300 border border-swat-500/30">
              {article.category}
            </span>
            <span className="px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider bg-white/10 text-white border border-white/15">
              Verified Guide
            </span>
          </div>

          <h1 className="text-3xl sm:text-4xl lg:text-5xl font-black text-white tracking-tight leading-tight">
            {article.title}
          </h1>

          <p className="text-lg text-mountain-300 leading-relaxed font-normal">
            {article.subtitle}
          </p>

          {/* Author & Meta Bar */}
          <div className="flex flex-wrap items-center justify-between gap-4 py-4 border-y border-mountain-800 text-xs text-mountain-400">
            <div className="flex items-center gap-3">
              <img
                src={article.author.avatarUrl}
                alt={article.author.name}
                className="w-10 h-10 rounded-full object-cover border border-mountain-700"
              />
              <div>
                <p className="font-bold text-white text-sm">{article.author.name}</p>
                <p className="text-mountain-400">{article.author.role}</p>
              </div>
            </div>

            <div className="flex items-center gap-4">
              <div className="flex items-center gap-1.5">
                <Calendar className="w-4 h-4 text-swat-400" />
                <span>Published: {article.publishedAt}</span>
              </div>
              <div className="flex items-center gap-1.5">
                <Clock className="w-4 h-4 text-swat-400" />
                <span>{article.readTime}</span>
              </div>
            </div>
          </div>
        </div>

        {/* Hero Cover Image */}
        <div className="rounded-3xl overflow-hidden mb-12 bg-mountain-900 border border-mountain-800 h-[360px] sm:h-[440px]">
          <img
            src={article.coverImage}
            alt={article.title}
            className="w-full h-full object-cover"
          />
        </div>

        {/* Article Body Content (Markdown formatting rendered cleanly) */}
        <article className="prose prose-invert prose-emerald max-w-none text-mountain-200 leading-relaxed space-y-6 mb-16">
          {article.content.split('\n\n').map((paragraph, idx) => {
            const trimmed = paragraph.trim();
            if (!trimmed) return null;

            // Simple clean header parser for H1, H2, H3 and quotes
            if (trimmed.startsWith('# ')) {
              return (
                <h2 key={idx} className="text-2xl sm:text-3xl font-extrabold text-white mt-8 mb-4 border-b border-mountain-800 pb-2">
                  {trimmed.replace('# ', '')}
                </h2>
              );
            }
            if (trimmed.startsWith('## ')) {
              return (
                <h3 key={idx} className="text-xl sm:text-2xl font-bold text-white mt-6 mb-3">
                  {trimmed.replace('## ', '')}
                </h3>
              );
            }
            if (trimmed.startsWith('### ')) {
              return (
                <h4 key={idx} className="text-lg font-bold text-swat-300 mt-4 mb-2">
                  {trimmed.replace('### ', '')}
                </h4>
              );
            }
            if (trimmed.startsWith('> ')) {
              return (
                <blockquote
                  key={idx}
                  className="p-4 my-6 rounded-2xl bg-swat-950/60 border-l-4 border-swat-500 text-swat-200 italic"
                >
                  {trimmed.replace('> ', '')}
                </blockquote>
              );
            }
            if (trimmed.startsWith('- ') || trimmed.startsWith('1. ')) {
              return (
                <div key={idx} className="pl-4 space-y-1 my-3">
                  {trimmed.split('\n').map((line, lIdx) => (
                    <div key={lIdx} className="flex items-start gap-2 text-sm text-mountain-200">
                      <CheckCircle2 className="w-4 h-4 text-swat-400 shrink-0 mt-1" />
                      <span>{line.replace(/^(- |\d+\. )/, '')}</span>
                    </div>
                  ))}
                </div>
              );
            }

            return (
              <p key={idx} className="text-base text-mountain-200 leading-relaxed">
                {trimmed}
              </p>
            );
          })}
        </article>

        {/* Article Tags Footer */}
        <div className="flex flex-wrap items-center justify-between gap-4 py-6 border-t border-mountain-800 mb-16">
          <div className="flex flex-wrap items-center gap-2">
            <Tag className="w-4 h-4 text-mountain-400" />
            <span className="text-xs font-semibold text-mountain-400">Tags:</span>
            {article.tags.map((tag, idx) => (
              <span
                key={idx}
                className="px-3 py-1 rounded-lg bg-mountain-900 text-mountain-300 text-xs font-semibold border border-mountain-800"
              >
                #{tag}
              </span>
            ))}
          </div>

          <Link
            href="/blog"
            className="inline-flex items-center gap-2 text-sm font-bold text-swat-400 hover:text-swat-300 transition-colors"
          >
            <ArrowLeft className="w-4 h-4" />
            <span>Back to All Guides</span>
          </Link>
        </div>

        {/* Related Articles Recommendation */}
        {relatedArticles.length > 0 && (
          <div className="mb-20">
            <h3 className="text-xl font-bold text-white mb-6">
              Related Guides in {article.category}
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
              {relatedArticles.map((rel) => (
                <Link
                  key={rel.id}
                  href={`/blog/${rel.slug}`}
                  className="p-5 rounded-2xl bg-mountain-900 border border-mountain-800 hover:border-swat-500/50 transition-all space-y-2"
                >
                  <span className="text-xs text-swat-400 font-bold">{rel.readTime}</span>
                  <h4 className="text-base font-bold text-white hover:text-swat-300 transition-colors line-clamp-2">
                    {rel.title}
                  </h4>
                  <p className="text-xs text-mountain-400 line-clamp-2">{rel.excerpt}</p>
                </Link>
              ))}
            </div>
          </div>
        )}

        {/* Download App CTA */}
        <CTASection />
      </div>
    </div>
  );
}
