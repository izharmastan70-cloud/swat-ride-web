'use client';

import React from 'react';
import Link from 'next/link';
import {
  Truck,
  ShieldCheck,
  Package,
  DollarSign,
  UserCheck,
  CreditCard,
  Radio,
  CheckCircle2,
  Download,
  ArrowRight,
  FileText,
  AlertTriangle,
  ShoppingBag,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { CTASection } from '@/components/common/CTASection';
import { cn } from '@/lib/utils';

export default function CargoServicePage() {
  const cargoTiers = [
    {
      name: 'Express Parcel',
      desc: 'Fast localized courier for documents, gifts, and retail parcels within Mingora & Saidu Sharif.',
      icon: <FileText className="w-6 h-6 text-sky-400" />,
      tag: 'Available Now',
    },
    {
      name: 'Economy Loader',
      desc: 'Suzuki pickup and small loader vans for house shifts and commercial stock transport.',
      icon: <Truck className="w-6 h-6 text-sky-400" />,
      tag: 'Available Now',
    },
    {
      name: 'Heavy Commercial',
      desc: 'Large commercial trucks for bulk goods and agricultural shipments across Swat valleys.',
      icon: <Package className="w-6 h-6 text-sky-400" />,
      tag: 'Available Now',
    },
    {
      name: 'Fragile Handling',
      desc: 'Specialized padding and verified low-speed transit for electronics, glass, and delicate items.',
      icon: <AlertTriangle className="w-6 h-6 text-amber-400" />,
      tag: 'Architecture Ready',
    },
    {
      name: 'Buy-For-Me Concierge',
      desc: 'Our driver purchases specific items from Mingora Bazaar and delivers them with original receipts.',
      icon: <ShoppingBag className="w-6 h-6 text-emerald-400" />,
      tag: 'Architecture Ready',
    },
  ];

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Services', href: '/#services' },
            { label: 'Cargo & Logistics' },
          ]}
        />

        {/* Hero Banner */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center mb-20">
          <div className="lg:col-span-7 space-y-6">
            <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-sky-950/80 border border-sky-500/40 text-xs font-semibold text-sky-300">
              <Truck className="w-4 h-4 text-sky-400" />
              <span>SWAT RIDE • Cargo & Logistics Service</span>
            </span>

            <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight leading-tight">
              Dependable Goods Transport & Commercial Loads Across{' '}
              <span className="bg-gradient-to-r from-sky-400 to-emerald-300 bg-clip-text text-transparent">
                Swat District
              </span>
            </h1>

            <p className="text-base sm:text-lg text-mountain-300 leading-relaxed max-w-2xl">
              From urgent legal documents in Mingora to heavy agricultural loads moving down from Kalam, book the exact vehicle tier you need with transparent weight and distance pricing.
            </p>

            <div className="flex flex-col sm:flex-row items-center gap-4 pt-2">
              <Link
                href="/download"
                className="inline-flex items-center justify-center gap-2.5 px-8 py-4 rounded-2xl bg-sky-600 hover:bg-sky-500 text-white font-bold text-base shadow-lg shadow-sky-600/30 transition-all w-full sm:w-auto"
              >
                <Download className="w-5 h-5" />
                <span>Book Cargo in App</span>
              </Link>
              <Link
                href="/cargo-driver"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl bg-white/10 hover:bg-white/15 text-white font-semibold text-base border border-white/15 transition-all w-full sm:w-auto"
              >
                <span>Become a Cargo Driver</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          {/* Right: Vehicle Tier Showcase */}
          <div className="lg:col-span-5">
            <div className="p-6 rounded-3xl bg-mountain-900 border border-mountain-800 shadow-glass-lg space-y-4">
              <div className="flex items-center justify-between border-b border-mountain-800 pb-3">
                <h3 className="text-base font-bold text-white">Supported Cargo Categories</h3>
                <span className="text-xs text-sky-400 font-semibold">Verified Tiers</span>
              </div>

              <div className="space-y-3">
                {cargoTiers.map((tier, idx) => (
                  <div
                    key={idx}
                    className="flex items-start gap-4 p-3.5 rounded-2xl bg-mountain-950/80 border border-mountain-800"
                  >
                    <div className="p-2.5 rounded-xl bg-mountain-900 border border-mountain-700 shrink-0">
                      {tier.icon}
                    </div>
                    <div>
                      <div className="flex items-center gap-2">
                        <h4 className="text-sm font-bold text-white">{tier.name}</h4>
                        <span className="px-2 py-0.5 text-[10px] rounded bg-sky-500/20 text-sky-300 font-semibold">
                          {tier.tag}
                        </span>
                      </div>
                      <p className="text-xs text-mountain-400 mt-1 leading-relaxed">
                        {tier.desc}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>

        {/* 7 Core Topics Grid */}
        <SectionHeader
          badge="End-to-End Logistics"
          title="Why Businesses & Families Rely on SWAT RIDE Cargo"
          subtitle="Transparent pricing, secure OTP delivery proof, and specialized vehicle matching protect every shipment."
        />

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-20">
          <div className="p-6 rounded-2xl bg-mountain-900/80 border border-mountain-800 space-y-3">
            <DollarSign className="w-6 h-6 text-sky-400" />
            <h3 className="text-lg font-bold text-white">Transparent Weight & Distance Pricing</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              No hidden handling surcharges. Prices are calculated dynamically based on distance, cargo tier, and vehicle capacity.
            </p>
          </div>

          <div className="p-6 rounded-2xl bg-mountain-900/80 border border-mountain-800 space-y-3">
            <UserCheck className="w-6 h-6 text-sky-400" />
            <h3 className="text-lg font-bold text-white">Verified Commercial Drivers</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              Every cargo driver holds a valid commercial license and passes strict background character checks in Swat.
            </p>
          </div>

          <div className="p-6 rounded-2xl bg-mountain-900/80 border border-mountain-800 space-y-3">
            <ShieldCheck className="w-6 h-6 text-sky-400" />
            <h3 className="text-lg font-bold text-white">Digital Proof & OTP Delivery</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              Drop-offs require recipient OTP verification or digital signature confirmation to ensure zero loss or misplacement.
            </p>
          </div>
        </div>

        <CTASection
          title="Need Reliable Goods Transport in Swat?"
          subtitle="Download the app today to inspect vehicle tiers and get instant logistics fare estimates."
          primaryCtaText="Book Cargo Now"
          primaryCtaLink="/download"
          secondaryCtaText="Apply as Cargo Driver"
          secondaryCtaLink="/cargo-driver"
        />
      </div>
    </div>
  );
}
