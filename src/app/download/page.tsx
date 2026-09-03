'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import {
  Download,
  Smartphone,
  ShieldCheck,
  CheckCircle2,
  QrCode,
  ArrowRight,
  HelpCircle,
  ExternalLink,
  Car,
  Utensils,
  Truck,
  GraduationCap,
  Hotel,
  Mountain,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { cn } from '@/lib/utils';

export default function AppDownloadPage() {
  const [selectedDeepLink, setSelectedDeepLink] = useState('ride');

  // Configurable URL from environment placeholder
  const playStoreUrl =
    process.env.NEXT_PUBLIC_GOOGLE_PLAY_URL ||
    'https://play.google.com/store/apps/details?id=pk.swatride.app.placeholder';

  const deepLinks = [
    { id: 'ride', label: 'Normal Ride', scheme: 'swatride://ride', icon: <Car className="w-4 h-4" /> },
    { id: 'food', label: 'Food Delivery', scheme: 'swatride://food', icon: <Utensils className="w-4 h-4" /> },
    { id: 'cargo', label: 'Cargo Logistics', scheme: 'swatride://cargo', icon: <Truck className="w-4 h-4" /> },
    { id: 'student', label: 'Student Ride', scheme: 'swatride://student', icon: <GraduationCap className="w-4 h-4" /> },
    { id: 'hotels', label: 'Hotels', scheme: 'swatride://hotels', icon: <Hotel className="w-4 h-4" /> },
    { id: 'tours', label: 'Tours & Tourism', scheme: 'swatride://tours', icon: <Mountain className="w-4 h-4" /> },
  ];

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'App', href: '/download' },
            { label: 'Download SWAT RIDE Android App' },
          ]}
        />

        {/* Hero Section */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center mb-20">
          <div className="lg:col-span-7 space-y-6">
            <div className="flex items-center gap-3">
              <img
                src="/logo.jpg"
                alt="SWAT RIDE Official Emblem"
                className="w-14 h-14 rounded-2xl object-cover shadow-glow-emerald border border-white/20 shrink-0"
              />
              <div>
                <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-swat-950/80 border border-swat-500/40 text-xs font-semibold text-swat-300">
                  <Smartphone className="w-4 h-4 text-swat-400" />
                  <span>ANDROID EXCLUSIVE • GOOGLE PLAY RELEASE</span>
                </span>
                <p className="text-xs text-mountain-400 mt-1">
                  Official Mobile Application for Swat, KPK
                </p>
              </div>
            </div>

            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-black text-white tracking-tight leading-tight">
              Download the Official{' '}
              <span className="bg-gradient-to-r from-swat-400 via-emerald-300 to-amber-300 bg-clip-text text-transparent">
                SWAT RIDE
              </span>{' '}
              Android App
            </h1>

            <p className="text-base sm:text-lg text-mountain-300 leading-relaxed max-w-2xl">
              Experience transparent upfront fare estimates, background-checked local Swat drivers, hot food delivery, school transport, hotels, and 4x4 Kalam mountain tours in one lightweight application.
            </p>

            {/* Google Play CTA */}
            <div className="flex flex-col sm:flex-row items-center gap-4 pt-2">
              <a
                href={playStoreUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center justify-center gap-3 px-8 py-4 rounded-2xl bg-swat-600 hover:bg-swat-500 text-white font-bold text-base shadow-lg shadow-swat-600/40 hover:shadow-swat-500/60 hover:-translate-y-0.5 transition-all w-full sm:w-auto"
              >
                <Download className="w-5 h-5" />
                <span>Get it on Google Play</span>
                <ExternalLink className="w-4 h-4 opacity-80" />
              </a>

              {/* iOS Future Readiness Note */}
              <div className="p-3 rounded-xl bg-mountain-900 border border-mountain-800 text-xs text-mountain-400 text-center sm:text-left">
                <span className="font-semibold text-mountain-300">iOS / iPhone Version:</span>{' '}
                Under development. Android Google Play is our primary current target.
              </div>
            </div>

            {/* System Requirements Pill */}
            <div className="pt-2 text-xs text-mountain-400 space-y-1">
              <p>
                <strong className="text-white">Minimum Requirements:</strong> Android 8.0 (Oreo) or higher • 2 GB RAM minimum recommended.
              </p>
              <p>
                Optimized for low-end devices and 3G cellular data across Swat, KPK.
              </p>
            </div>
          </div>

          {/* Right: QR Code & Deep Link Tester Card */}
          <div className="lg:col-span-5">
            <div className="p-8 rounded-3xl bg-mountain-900 border border-mountain-800 shadow-glass-lg space-y-6">
              <div className="flex items-center justify-between border-b border-mountain-800 pb-4">
                <h3 className="text-lg font-bold text-white">Scan to Download</h3>
                <span className="text-xs text-swat-400 font-semibold uppercase">QR Ready</span>
              </div>

              {/* Simulated QR Box */}
              <div className="flex flex-col items-center justify-center p-6 rounded-2xl bg-mountain-950 border border-mountain-800 text-center space-y-3">
                <div className="w-36 h-36 rounded-2xl bg-white p-3 flex items-center justify-center shadow-md">
                  <QrCode className="w-32 h-32 text-mountain-950" />
                </div>
                <p className="text-xs text-mountain-300 font-medium">
                  Scan with your Android camera or QR reader to open Google Play
                </p>
              </div>

              {/* Deep Link Architecture Preview */}
              <div className="space-y-3 pt-2">
                <div className="text-xs font-bold uppercase text-mountain-400">
                  Deep-Link Router Demonstration
                </div>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                  {deepLinks.map((link) => (
                    <button
                      key={link.id}
                      onClick={() => setSelectedDeepLink(link.id)}
                      className={cn(
                        'flex items-center gap-1.5 p-2 rounded-xl border text-xs font-semibold transition-all',
                        selectedDeepLink === link.id
                          ? 'bg-swat-950 text-swat-400 border-swat-500'
                          : 'bg-mountain-950/60 text-mountain-400 border-mountain-800'
                      )}
                    >
                      {link.icon}
                      <span className="truncate">{link.label}</span>
                    </button>
                  ))}
                </div>

                <div className="p-3 rounded-xl bg-mountain-950 border border-mountain-800 text-xs text-mountain-300 flex items-center justify-between">
                  <span className="font-mono text-[11px] text-swat-400">
                    {deepLinks.find((l) => l.id === selectedDeepLink)?.scheme}
                  </span>
                  <span className="text-[10px] text-mountain-400">
                    Fallback: /download
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* 4 App Features Grid */}
        <SectionHeader
          badge="Why Download"
          title="Designed for Your Daily Life in Swat"
          subtitle="Discover why thousands across Mingora, Saidu Sharif, and Kalam trust the SWAT RIDE app."
        />

        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6 mb-20">
          <div className="p-6 rounded-2xl bg-mountain-900/80 border border-mountain-800 space-y-3">
            <CheckCircle2 className="w-6 h-6 text-swat-400" />
            <h3 className="text-lg font-bold text-white">Upfront Fares</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              Check exact estimated trip fares instantly before booking your Normal Ride or 4x4 Kalam tour.
            </p>
          </div>

          <div className="p-6 rounded-2xl bg-mountain-900/80 border border-mountain-800 space-y-3">
            <ShieldCheck className="w-6 h-6 text-swat-400" />
            <h3 className="text-lg font-bold text-white">Verified KPK Drivers</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              All drivers hold verified CNICs, valid driving licenses, and clean security backgrounds in Swat.
            </p>
          </div>

          <div className="p-6 rounded-2xl bg-mountain-900/80 border border-mountain-800 space-y-3">
            <Smartphone className="w-6 h-6 text-swat-400" />
            <h3 className="text-lg font-bold text-white">Multilingual Support</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              Use the app comfortably in English, Urdu, or Pashto with regional script rendering.
            </p>
          </div>

          <div className="p-6 rounded-2xl bg-mountain-900/80 border border-mountain-800 space-y-3">
            <Download className="w-6 h-6 text-swat-400" />
            <h3 className="text-lg font-bold text-white">Fast & Lightweight</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              Optimized footprint designed for rapid loading even on 3G mobile data networks in remote valleys.
            </p>
          </div>
        </div>

        {/* Bottom Help Banner */}
        <div className="p-8 rounded-3xl bg-mountain-900 border border-mountain-800 text-center space-y-3">
          <HelpCircle className="w-8 h-8 text-swat-400 mx-auto" />
          <h3 className="text-xl font-bold text-white">Need Installation Assistance?</h3>
          <p className="text-xs text-mountain-400 max-w-md mx-auto">
            If you encounter any issue downloading or installing the app on your Android smartphone, visit our Help Center or contact our Mingora support line.
          </p>
          <div className="pt-2">
            <Link
              href="/help"
              className="inline-block px-6 py-2.5 rounded-xl bg-mountain-800 hover:bg-mountain-700 text-white text-xs font-bold transition-all"
            >
              Visit Help & FAQ Center
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
