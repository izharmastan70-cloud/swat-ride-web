'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import {
  Car,
  ShieldCheck,
  Navigation,
  DollarSign,
  UserCheck,
  Radio,
  CreditCard,
  Star,
  ShieldAlert,
  Download,
  ArrowRight,
  CheckCircle2,
  MapPin,
  Clock,
  ChevronRight,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { CTASection } from '@/components/common/CTASection';
import { cn } from '@/lib/utils';

export default function RideServicePage() {
  const [pickup, setPickup] = useState('Mingora Bazaar');
  const [destination, setDestination] = useState('Saidu Sharif Hospital');
  const [selectedTier, setSelectedTier] = useState<'normal' | 'comfort'>('normal');

  // Interactive Fare Simulator (Transparent upfront estimation demonstration)
  const estimatedPKR = selectedTier === 'normal' ? 240 : 350;

  const rideSteps = [
    {
      step: '01',
      title: 'Set Pickup & Destination',
      desc: 'Enter your pickup point and destination across Mingora, Saidu Sharif, or Swat valleys with GPS auto-locate.',
      icon: <MapPin className="w-5 h-5 text-swat-400" />,
    },
    {
      step: '02',
      title: 'Vehicle Selection & Upfront Fare',
      desc: 'Choose your vehicle tier and view transparent upfront fare estimates before confirming your booking.',
      icon: <DollarSign className="w-5 h-5 text-swat-400" />,
    },
    {
      step: '03',
      title: 'Instant Driver Matching',
      desc: 'Our intelligent Mingora dispatch connects you to the nearest background-checked KPK driver in seconds.',
      icon: <UserCheck className="w-5 h-5 text-swat-400" />,
    },
    {
      step: '04',
      title: 'Live Tracking & Trip Sharing',
      desc: 'Watch your vehicle approach in real-time and share a live tracking link with trusted family contacts.',
      icon: <Radio className="w-5 h-5 text-swat-400" />,
    },
    {
      step: '05',
      title: 'Flexible Payment Options',
      desc: 'Pay cash on arrival or use in-app SWAT RIDE wallet balance with instant digital receipts.',
      icon: <CreditCard className="w-5 h-5 text-swat-400" />,
    },
    {
      step: '06',
      title: 'Rating & Verified SOS Safety',
      desc: 'Rate your driver to maintain high community standards. 24/7 emergency SOS protection is active on every trip.',
      icon: <ShieldAlert className="w-5 h-5 text-red-400" />,
    },
  ];

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Services', href: '/#services' },
            { label: 'Normal Ride' },
          ]}
        />

        {/* Hero Section */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center mb-20">
          <div className="lg:col-span-7 space-y-6">
            <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-swat-950/80 border border-swat-500/40 text-xs font-semibold text-swat-300">
              <Car className="w-4 h-4 text-swat-400" />
              <span>SWAT RIDE • Normal Ride Service</span>
            </span>

            <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight leading-tight">
              Reliable Daily City & Valley Rides with{' '}
              <span className="bg-gradient-to-r from-swat-400 to-emerald-300 bg-clip-text text-transparent">
                Upfront Fares
              </span>
            </h1>

            <p className="text-base sm:text-lg text-mountain-300 leading-relaxed max-w-2xl">
              Travel comfortably across Mingora, Saidu Sharif, Fiza Gat, Bahrain, and Kalam. No bargaining over fares, no hidden surcharges—just transparent upfront estimates and background-checked local drivers you can trust.
            </p>

            <div className="flex flex-col sm:flex-row items-center gap-4 pt-2">
              <Link
                href="/download"
                className="inline-flex items-center justify-center gap-2.5 px-8 py-4 rounded-2xl bg-swat-600 hover:bg-swat-500 text-white font-bold text-base shadow-lg shadow-swat-600/40 transition-all w-full sm:w-auto"
              >
                <Download className="w-5 h-5" />
                <span>Download App to Ride</span>
              </Link>
              <Link
                href="/driver"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl bg-white/10 hover:bg-white/15 text-white font-semibold text-base border border-white/15 transition-all w-full sm:w-auto"
              >
                <span>Become a Driver</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          {/* Right: Interactive Upfront Fare Estimator Simulator */}
          <div className="lg:col-span-5">
            <div className="rounded-3xl bg-mountain-900 border border-mountain-800 shadow-glass-lg overflow-hidden space-y-6">
              {/* Top Vehicle Banner */}
              <div className="relative h-48 bg-mountain-800 overflow-hidden">
                <img
                  src="/images/swat-ride-vehicle.jpg"
                  alt="SWAT RIDE Vehicle"
                  className="w-full h-full object-cover"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-mountain-900 via-mountain-900/30 to-transparent" />
                <div className="absolute bottom-3 left-4 right-4 flex items-center justify-between">
                  <span className="px-2.5 py-1 text-xs font-bold rounded-lg bg-swat-950/90 text-swat-300 border border-swat-500/40">
                    Normal Ride Fleet • Mingora & Swat
                  </span>
                  <span className="text-xs font-mono font-bold text-white bg-mountain-950/80 px-2 py-1 rounded">
                    UPFRONT FARE
                  </span>
                </div>
              </div>

              <div className="p-6 sm:p-8 pt-2 space-y-6">
                <div className="flex items-center justify-between border-b border-mountain-800 pb-4">
                  <h3 className="text-lg font-bold text-white">Upfront Fare Calculator</h3>
                  <span className="text-xs text-swat-400 font-semibold uppercase">Live Demo</span>
                </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-mountain-300 uppercase mb-1.5">
                    Pickup Location
                  </label>
                  <input
                    type="text"
                    value={pickup}
                    onChange={(e) => setPickup(e.target.value)}
                    className="w-full px-4 py-2.5 bg-mountain-950 border border-mountain-800 rounded-xl text-white text-sm focus:outline-none focus:ring-2 focus:ring-swat-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-mountain-300 uppercase mb-1.5">
                    Destination
                  </label>
                  <input
                    type="text"
                    value={destination}
                    onChange={(e) => setDestination(e.target.value)}
                    className="w-full px-4 py-2.5 bg-mountain-950 border border-mountain-800 rounded-xl text-white text-sm focus:outline-none focus:ring-2 focus:ring-swat-500"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3 pt-2">
                  <button
                    onClick={() => setSelectedTier('normal')}
                    className={cn(
                      'p-3 rounded-xl border text-left transition-all',
                      selectedTier === 'normal'
                        ? 'border-swat-500 bg-swat-950/50 text-white'
                        : 'border-mountain-800 bg-mountain-950/60 text-mountain-400'
                    )}
                  >
                    <div className="font-bold text-sm">Normal Ride</div>
                    <div className="text-xs mt-0.5 opacity-80">Everyday Comfort</div>
                  </button>
                  <button
                    onClick={() => setSelectedTier('comfort')}
                    className={cn(
                      'p-3 rounded-xl border text-left transition-all',
                      selectedTier === 'comfort'
                        ? 'border-swat-500 bg-swat-950/50 text-white'
                        : 'border-mountain-800 bg-mountain-950/60 text-mountain-400'
                    )}
                  >
                    <div className="font-bold text-sm">Comfort Sedan</div>
                    <div className="text-xs mt-0.5 opacity-80">Extra Legroom & AC</div>
                  </button>
                </div>
              </div>

              {/* Fare Result Banner */}
              <div className="p-4 rounded-2xl bg-swat-950 border border-swat-500/40 flex items-center justify-between">
                <div>
                  <div className="text-xs text-swat-300 font-medium">Estimated Upfront Fare</div>
                  <div className="text-2xl font-black text-white">PKR {estimatedPKR} - {estimatedPKR + 35}</div>
                </div>
                <Link
                  href="/download"
                  className="px-4 py-2 rounded-xl bg-swat-600 hover:bg-swat-500 text-white text-xs font-bold transition-all"
                >
                  Book Now
                </Link>
              </div>

              <p className="text-[11px] text-mountain-400 text-center">
                *Demo estimate based on standard Mingora to Saidu Sharif municipal tariff.
              </p>
            </div>
            </div>
          </div>
        </div>

        {/* 9 Complete Pillars of Normal Ride */}
        <SectionHeader
          badge="Complete Workflow"
          title="How SWAT RIDE Normal Ride Works"
          subtitle="From your first tap to arrival, experience transparent safety and professional KPK hospitality."
        />

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-20">
          {rideSteps.map((item, idx) => (
            <div
              key={idx}
              className="p-6 rounded-2xl bg-mountain-900/80 border border-mountain-800 hover:border-swat-500/40 transition-all space-y-4"
            >
              <div className="flex items-center justify-between">
                <span className="text-sm font-black text-swat-400 font-mono">STEP {item.step}</span>
                <div className="w-10 h-10 rounded-xl bg-mountain-950/80 border border-mountain-800 flex items-center justify-center">
                  {item.icon}
                </div>
              </div>
              <h3 className="text-lg font-bold text-white">{item.title}</h3>
              <p className="text-sm text-mountain-300 leading-relaxed">{item.desc}</p>
            </div>
          ))}
        </div>

        {/* Driver CTA Banner */}
        <CTASection
          title="Drive with Swat’s Own Mobility Platform"
          subtitle="Own a car in Mingora or Saidu Sharif? Enjoy flexible hours, fair commissions, and weekly transparent payouts."
          primaryCtaText="Apply to Become a Driver"
          primaryCtaLink="/driver"
          secondaryCtaText="Download Rider App"
          secondaryCtaLink="/download"
        />
      </div>
    </div>
  );
}
