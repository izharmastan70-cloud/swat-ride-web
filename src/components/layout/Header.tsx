'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Menu, ChevronDown, Download, ShieldCheck, Car, Store, Bike, Truck, GraduationCap, Hotel, Mountain, Compass } from 'lucide-react';
import { PRIMARY_NAV_ITEMS } from '@/data/navigation';
import { Locale } from '@/types';
import { translateText } from '@/i18n/dictionaries';
import { cn } from '@/lib/utils';
import { LanguageSwitcher } from './LanguageSwitcher';
import { MobileMenu } from './MobileMenu';

export interface HeaderProps {
  locale?: Locale;
  onLocaleChange?: (locale: Locale) => void;
}

const PARTNER_ICONS: Record<string, React.ReactNode> = {
  Car: <Car className="w-4 h-4 text-swat-400" />,
  Store: <Store className="w-4 h-4 text-amber-400" />,
  Bike: <Bike className="w-4 h-4 text-emerald-400" />,
  Truck: <Truck className="w-4 h-4 text-sky-400" />,
  GraduationCap: <GraduationCap className="w-4 h-4 text-purple-400" />,
  Hotel: <Hotel className="w-4 h-4 text-teal-400" />,
  Mountain: <Mountain className="w-4 h-4 text-emerald-300" />,
  Compass: <Compass className="w-4 h-4 text-yellow-400" />,
};

export const Header: React.FC<HeaderProps> = ({
  locale = 'en',
  onLocaleChange = () => {},
}) => {
  const [isScrolled, setIsScrolled] = useState(false);
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [activeMegaMenu, setActiveMegaMenu] = useState<string | null>(null);
  const pathname = usePathname();

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  return (
    <>
      <header
        className={cn(
          'sticky top-0 z-40 w-full transition-all duration-300',
          isScrolled
            ? 'bg-mountain-950/90 backdrop-blur-xl border-b border-white/10 shadow-glass-md py-3'
            : 'bg-gradient-to-b from-mountain-950/80 to-transparent py-4'
        )}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between">
            {/* Logo / Brand identity */}
            <Link href="/" className="flex items-center gap-2.5 group">
              <img
                src="/logo.jpg"
                alt="SWAT RIDE Official Logo"
                className="w-10 h-10 rounded-xl object-cover shadow-glow-emerald border border-white/20 transition-transform duration-300 group-hover:scale-105"
              />
              <div className="flex flex-col">
                <span className="text-xl font-black tracking-tight text-white group-hover:text-swat-300 transition-colors">
                  SWAT RIDE
                </span>
                <span className="text-[10px] font-bold tracking-widest uppercase text-swat-400 -mt-1">
                  Swat • KPK • Pakistan
                </span>
              </div>
            </Link>

            {/* Desktop Navigation */}
            <nav className="hidden lg:flex items-center space-x-1 xl:space-x-2">
              {PRIMARY_NAV_ITEMS.map((item, index) => {
                const labelText = translateText(item.label, locale);
                const hasChildren = item.children && item.children.length > 0;
                const isActive = pathname === item.href;

                if (hasChildren) {
                  return (
                    <div
                      key={index}
                      className="relative"
                      onMouseEnter={() => setActiveMegaMenu(item.href)}
                      onMouseLeave={() => setActiveMegaMenu(null)}
                    >
                      <button
                        className={cn(
                          'inline-flex items-center gap-1 px-3.5 py-2 text-sm font-semibold rounded-xl transition-colors',
                          isActive || activeMegaMenu === item.href
                            ? 'text-swat-400 bg-white/10'
                            : 'text-mountain-200 hover:text-white hover:bg-white/5'
                        )}
                      >
                        <span>{labelText}</span>
                        <ChevronDown className="w-3.5 h-3.5 transition-transform duration-200" />
                      </button>

                      {/* Mega Menu Dropdown */}
                      {activeMegaMenu === item.href && (
                        <div className="absolute left-1/2 -translate-x-1/2 mt-2 w-[680px] rounded-2xl bg-mountain-900/95 backdrop-blur-2xl border border-white/15 shadow-glass-lg p-6 grid grid-cols-3 gap-4 z-50">
                          {item.children!.map((child, cIdx) => (
                            <Link
                              key={cIdx}
                              href={child.href}
                              onClick={() => setActiveMegaMenu(null)}
                              className="flex items-start gap-3 p-3 rounded-xl hover:bg-mountain-800/80 transition-colors group/item"
                            >
                              <div className="flex items-center justify-center w-8 h-8 rounded-lg bg-mountain-950/80 border border-mountain-700/60 shrink-0">
                                {child.iconName ? PARTNER_ICONS[child.iconName] || <ShieldCheck className="w-4 h-4" /> : null}
                              </div>
                              <div>
                                <h4 className="text-sm font-bold text-white group-hover/item:text-swat-400 transition-colors">
                                  {translateText(child.label, locale)}
                                </h4>
                                {child.description && (
                                  <p className="text-xs text-mountain-400 mt-0.5 leading-snug">
                                    {translateText(child.description, locale)}
                                  </p>
                                )}
                              </div>
                            </Link>
                          ))}
                        </div>
                      )}
                    </div>
                  );
                }

                return (
                  <Link
                    key={index}
                    href={item.href}
                    className={cn(
                      'px-3.5 py-2 text-sm font-semibold rounded-xl transition-colors',
                      isActive
                        ? 'text-swat-400 bg-white/10'
                        : 'text-mountain-200 hover:text-white hover:bg-white/5'
                    )}
                  >
                    {labelText}
                  </Link>
                );
              })}
            </nav>

            {/* Right CTAs & Language Switcher */}
            <div className="hidden lg:flex items-center gap-3">
              <LanguageSwitcher currentLocale={locale} onLocaleChange={onLocaleChange} />

              <Link
                href="/download"
                className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-swat-600 hover:bg-swat-500 text-white font-bold text-sm shadow-lg shadow-swat-600/30 hover:shadow-swat-500/50 hover:-translate-y-0.5 transition-all duration-200"
              >
                <Download className="w-4 h-4" />
                <span>Download App</span>
              </Link>
            </div>

            {/* Mobile Hamburger Menu Trigger */}
            <div className="flex items-center gap-2 lg:hidden">
              <LanguageSwitcher currentLocale={locale} onLocaleChange={onLocaleChange} />

              <button
                onClick={() => setIsMobileMenuOpen(true)}
                className="p-2 text-mountain-200 hover:text-white bg-white/10 hover:bg-white/15 rounded-xl border border-white/10 transition-colors focus:outline-none focus:ring-2 focus:ring-swat-500"
                aria-label="Open mobile menu"
              >
                <Menu className="w-6 h-6" />
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Responsive Mobile Drawer */}
      <MobileMenu
        isOpen={isMobileMenuOpen}
        onClose={() => setIsMobileMenuOpen(false)}
        navItems={PRIMARY_NAV_ITEMS}
        locale={locale}
        onLocaleChange={onLocaleChange}
      />
    </>
  );
};
