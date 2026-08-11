'use client';

import React, { useState, useRef, useEffect } from 'react';
import { Globe, Check } from 'lucide-react';
import { Locale } from '@/types';
import { UI_DICTIONARY, getUIText } from '@/i18n/dictionaries';
import { cn } from '@/lib/utils';

export interface LanguageSwitcherProps {
  currentLocale: Locale;
  onLocaleChange: (locale: Locale) => void;
  className?: string;
}

const LOCALES: { code: Locale; name: string; nativeName: string }[] = [
  { code: 'en', name: 'English', nativeName: 'English' },
  { code: 'ur', name: 'Urdu', nativeName: 'اردو' },
  { code: 'ps', name: 'Pashto', nativeName: 'پښتو' },
];

export const LanguageSwitcher: React.FC<LanguageSwitcherProps> = ({
  currentLocale,
  onLocaleChange,
  className,
}) => {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (dropdownRef.current && !dropdownRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const selectedLocale = LOCALES.find((l) => l.code === currentLocale) || LOCALES[0];

  return (
    <div ref={dropdownRef} className={cn('relative inline-block text-left', className)}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-white/10 hover:bg-white/15 border border-white/10 text-xs font-semibold text-white transition-colors focus:outline-none focus:ring-2 focus:ring-swat-400"
        aria-haspopup="true"
        aria-expanded={isOpen}
        aria-label="Select language"
      >
        <Globe className="w-3.5 h-3.5 text-swat-400" />
        <span>{selectedLocale.nativeName}</span>
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-44 origin-top-right rounded-2xl bg-mountain-900 border border-mountain-800 shadow-glass-lg z-50 overflow-hidden">
          <div className="py-1">
            {LOCALES.map((locale) => (
              <button
                key={locale.code}
                onClick={() => {
                  onLocaleChange(locale.code);
                  setIsOpen(false);
                }}
                className={cn(
                  'w-full flex items-center justify-between px-4 py-2.5 text-xs text-left transition-colors hover:bg-mountain-800',
                  currentLocale === locale.code ? 'text-swat-400 font-bold bg-mountain-950/50' : 'text-mountain-200'
                )}
              >
                <div>
                  <span className="block text-sm">{locale.nativeName}</span>
                  <span className="block text-[10px] text-mountain-400">{locale.name}</span>
                </div>
                {currentLocale === locale.code && <Check className="w-4 h-4 text-swat-400" />}
              </button>
            ))}
          </div>
          <div className="px-3 py-1.5 bg-mountain-950 border-t border-mountain-800 text-[10px] text-mountain-400">
            Official regional translation
          </div>
        </div>
      )}
    </div>
  );
};
