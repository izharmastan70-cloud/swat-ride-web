'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { X, ChevronDown, ChevronUp, PhoneCall, ShieldAlert, Download } from 'lucide-react';
import { NavItem, Locale } from '@/types';
import { translateText } from '@/i18n/dictionaries';
import { cn } from '@/lib/utils';
import { LanguageSwitcher } from './LanguageSwitcher';

export interface MobileMenuProps {
  isOpen: boolean;
  onClose: () => void;
  navItems: NavItem[];
  locale: Locale;
  onLocaleChange: (locale: Locale) => void;
}

export const MobileMenu: React.FC<MobileMenuProps> = ({
  isOpen,
  onClose,
  navItems,
  locale,
  onLocaleChange,
}) => {
  const [expandedIndex, setExpandedIndex] = useState<number | null>(null);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex flex-col bg-mountain-950/95 backdrop-blur-2xl text-white overflow-y-auto lg:hidden">
      {/* Top Header Bar */}
      <div className="flex items-center justify-between px-6 py-4 border-b border-mountain-800 bg-mountain-900/60">
        <Link href="/" onClick={onClose} className="flex items-center gap-2">
          <span className="text-xl font-extrabold tracking-tight bg-gradient-to-r from-swat-400 to-emerald-300 bg-clip-text text-transparent">
            SWAT RIDE
          </span>
          <span className="px-2 py-0.5 text-[10px] font-bold uppercase rounded bg-swat-600/20 text-swat-300 border border-swat-500/30">
            KPK
          </span>
        </Link>
        <button
          onClick={onClose}
          className="p-2 text-mountain-300 hover:text-white bg-mountain-800/80 rounded-xl transition-colors focus:outline-none"
          aria-label="Close mobile menu"
        >
          <X className="w-6 h-6" />
        </button>
      </div>

      {/* Language Switcher Bar */}
      <div className="flex items-center justify-between px-6 py-3 border-b border-mountain-800/60 bg-mountain-900/30">
        <span className="text-xs text-mountain-400 font-medium">Select Language</span>
        <LanguageSwitcher currentLocale={locale} onLocaleChange={onLocaleChange} />
      </div>

      {/* Navigation List */}
      <div className="flex-1 px-6 py-4 space-y-2">
        {navItems.map((item, index) => {
          const itemLabel = translateText(item.label, locale);
          const hasChildren = item.children && item.children.length > 0;
          const isExpanded = expandedIndex === index;

          return (
            <div key={index} className="border-b border-mountain-800/40 pb-2">
              <div className="flex items-center justify-between">
                <Link
                  href={item.href}
                  onClick={onClose}
                  className="block py-2.5 text-base font-semibold text-mountain-100 hover:text-swat-400 transition-colors"
                >
                  {itemLabel}
                </Link>
                {hasChildren && (
                  <button
                    onClick={() => setExpandedIndex(isExpanded ? null : index)}
                    className="p-2 text-mountain-400 hover:text-white focus:outline-none"
                    aria-label="Toggle sub-menu"
                  >
                    {isExpanded ? <ChevronUp className="w-5 h-5" /> : <ChevronDown className="w-5 h-5" />}
                  </button>
                )}
              </div>

              {/* Sub-menu items for Partners */}
              {hasChildren && isExpanded && (
                <div className="pl-4 mt-1 mb-3 space-y-2 border-l-2 border-swat-500/40">
                  {item.children!.map((child, cIdx) => (
                    <Link
                      key={cIdx}
                      href={child.href}
                      onClick={onClose}
                      className="block py-1.5 text-sm text-mountain-300 hover:text-white transition-colors"
                    >
                      {translateText(child.label, locale)}
                    </Link>
                  ))}
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Emergency SOS & Download CTA Footer */}
      <div className="p-6 border-t border-mountain-800 bg-mountain-900/80 space-y-3">
        <Link
          href="/safety"
          onClick={onClose}
          className="flex items-center justify-center gap-2 w-full py-3 px-4 rounded-xl bg-red-600/20 hover:bg-red-600/30 border border-red-500/40 text-red-300 font-semibold text-sm transition-colors"
        >
          <ShieldAlert className="w-4 h-4" />
          <span>Safety & SOS Emergency Center</span>
        </Link>
        <Link
          href="/download"
          onClick={onClose}
          className="flex items-center justify-center gap-2 w-full py-3.5 px-4 rounded-xl bg-swat-600 hover:bg-swat-500 text-white font-bold text-sm shadow-lg shadow-swat-600/30 transition-all"
        >
          <Download className="w-4 h-4" />
          <span>Download Android App</span>
        </Link>
      </div>
    </div>
  );
};
