'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import {
  Download,
  ArrowRight,
  ShieldCheck,
  CheckCircle2,
  MapPin,
  Car,
  Utensils,
  Truck,
  GraduationCap,
  Hotel,
  Mountain,
  Compass,
  Store,
  Bike,
  ShieldAlert,
  Gift,
  HelpCircle,
  ChevronDown,
  ChevronUp,
  Smartphone,
  Navigation,
  Clock,
  Wallet,
} from 'lucide-react';
import { Hero3DCanvas } from '@/components/3d/Hero3DCanvas';
import { ServiceCard3D } from '@/components/3d/ServiceCard3D';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { CTASection } from '@/components/common/CTASection';
import { SWAT_SERVICES } from '@/data/services';
import { PARTNER_ROLES } from '@/data/partners';
import { SWAT_LOCATIONS } from '@/data/locations';
import { BLOG_ARTICLES } from '@/data/blog';
import { HELP_ARTICLES } from '@/data/help';
import { translateText } from '@/i18n/dictionaries';
import { cn } from '@/lib/utils';

export default function HomePage() {
  const [openFaq, setOpenFaq] = useState<string | null>('sos-how-it-works');

  return (
    <div className="relative overflow-hidden">
      {/* ======================================================================
          1. PREMIUM 3D HERO SECTION
         ====================================================================== */}
      <section className="relative pt-8 pb-16 sm:pt-12 sm:pb-24 lg:pt-16 lg:pb-32 overflow-hidden">
        {/* Subtle decorative background gradients */}
        <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full max-w-7xl h-[600px] bg-gradient-radial from-swat-600/15 via-mountain-900/40 to-transparent blur-3xl pointer-events-none" />
        <div className="absolute top-20 right-0 w-96 h-96 rounded-full bg-amber-500/10 blur-3xl pointer-events-none" />

        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
            {/* Left Col: Hero Value Proposition */}
            <div className="lg:col-span-6 space-y-6 text-center lg:text-left z-10">
              <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-swat-950/80 border border-swat-500/40 text-xs font-semibold text-swat-300 shadow-glass-sm">
                <ShieldCheck className="w-4 h-4 text-swat-400" />
                <span>Verified Local Swat Ecosystem • Transparent Upfront Fares</span>
              </div>

              <h1 className="text-4xl sm:text-5xl lg:text-6xl font-black text-white tracking-tight leading-[1.1]">
                Your Trusted Premium Mobility & Ecosystem in{' '}
                <span className="bg-gradient-to-r from-swat-400 via-emerald-300 to-amber-300 bg-clip-text text-transparent">
                  Swat, KPK
                </span>
              </h1>

              <p className="text-base sm:text-lg text-mountain-300 leading-relaxed max-w-xl mx-auto lg:mx-0">
                SWAT RIDE connects passengers, families, and businesses across Mingora, Saidu Sharif, Bahrain, Kalam, and Malam Jabba. Experience reliable normal rides, hot food delivery, cargo logistics, monthly school transport, hotels, and rugged 4x4 mountain tours in one single app.
              </p>

              {/* Primary & Secondary Hero CTAs */}
              <div className="flex flex-col sm:flex-row items-center justify-center lg:justify-start gap-4 pt-2">
                <Link
                  href="/download"
                  className="inline-flex items-center justify-center gap-2.5 px-8 py-4 rounded-2xl bg-swat-600 hover:bg-swat-500 text-white font-bold text-base shadow-lg shadow-swat-600/40 hover:shadow-swat-500/60 hover:-translate-y-0.5 transition-all duration-200 w-full sm:w-auto"
                >
                  <Download className="w-5 h-5" />
                  <span>Download Android App</span>
                </Link>

                <a
                  href="#services"
                  className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl bg-white/10 hover:bg-white/15 text-white font-semibold text-base border border-white/15 backdrop-blur-md hover:-translate-y-0.5 transition-all duration-200 w-full sm:w-auto"
                >
                  <span>Explore Services</span>
                  <ArrowRight className="w-4 h-4" />
                </a>
              </div>

              {/* Verified Features Pill */}
              <div className="flex flex-wrap items-center justify-center lg:justify-start gap-4 pt-4 text-xs font-medium text-mountain-400">
                <div className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-4 h-4 text-swat-400" />
                  <span>Upfront Fare Estimate</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-4 h-4 text-swat-400" />
                  <span>Verified KPK Drivers</span>
                </div>
                <div className="flex items-center gap-1.5">
                  <CheckCircle2 className="w-4 h-4 text-swat-400" />
                  <span>24/7 Emergency SOS</span>
                </div>
              </div>
            </div>

            {/* Right Col: Premium 3D Interactive Hero Canvas */}
            <div className="lg:col-span-6 w-full h-[400px] sm:h-[480px] lg:h-[540px]">
              <Hero3DCanvas />
            </div>
          </div>
        </div>
      </section>

      {/* ======================================================================
          1.5. OFFICIAL BRAND & SWAT VEHICLE FLEET SHOWCASE
         ====================================================================== */}
      <section className="relative py-12 sm:py-16 bg-mountain-900/60 border-y border-white/10">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex flex-col lg:flex-row items-center justify-between gap-8 mb-12">
            {/* Official Logo Identity Card */}
            <div className="flex items-center gap-5 p-6 rounded-3xl bg-gradient-to-r from-mountain-900 to-mountain-950 border border-swat-500/40 shadow-glass-md w-full lg:w-auto">
              <img
                src="/logo.jpg"
                alt="SWAT RIDE Official Emblem"
                className="w-20 h-20 sm:w-24 sm:h-24 rounded-2xl object-cover shadow-glow-emerald border border-white/20 shrink-0"
              />
              <div>
                <span className="px-2.5 py-0.5 rounded text-[10px] font-bold uppercase tracking-wider bg-swat-600/20 text-swat-300 border border-swat-500/30">
                  Official Verified Emblem
                </span>
                <h3 className="text-2xl font-black text-white mt-1">SWAT RIDE</h3>
                <p className="text-xs text-mountain-300 mt-0.5">
                  The Mountain Mobility & Service Network of Swat, KPK
                </p>
              </div>
            </div>

            <div className="text-center lg:text-right max-w-lg">
              <h3 className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight">
                Terrain-Matched Swat Vehicle Fleet
              </h3>
              <p className="text-sm text-mountain-300 mt-2">
                Every vehicle in our Swat network is inspected for mountain safety, braking performance, and passenger comfort across Mingora, Kalam, and Malam Jabba.
              </p>
            </div>
          </div>

          {/* 4 Fleet Image Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            <div className="group rounded-2xl bg-mountain-900 border border-mountain-800 hover:border-swat-500/50 overflow-hidden shadow-glass-sm transition-all duration-300 flex flex-col justify-between">
              <div className="h-44 bg-mountain-800 relative overflow-hidden">
                <img
                  src="/images/swat-ride-vehicle.jpg"
                  alt="Normal Ride Fleet"
                  className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-mountain-950 via-transparent to-transparent" />
                <span className="absolute bottom-3 left-3 px-2.5 py-1 text-xs font-bold rounded-md bg-swat-950/90 text-swat-300 border border-swat-500/30">
                  Normal Ride Sedan / SUV
                </span>
              </div>
              <div className="p-4 text-xs text-mountain-300 leading-relaxed">
                Daily city and valley transit across Mingora, Saidu Sharif, and Fiza Gat with transparent upfront fares.
              </div>
            </div>

            <div className="group rounded-2xl bg-mountain-900 border border-mountain-800 hover:border-emerald-500/50 overflow-hidden shadow-glass-sm transition-all duration-300 flex flex-col justify-between">
              <div className="h-44 bg-mountain-800 relative overflow-hidden">
                <img
                  src="/images/swat-4x4-jeep.jpg"
                  alt="4x4 Mountain Tourism Jeep"
                  className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-mountain-950 via-transparent to-transparent" />
                <span className="absolute bottom-3 left-3 px-2.5 py-1 text-xs font-bold rounded-md bg-emerald-950/90 text-emerald-300 border border-emerald-500/30">
                  4x4 Kalam & Mahodand Jeep
                </span>
              </div>
              <div className="p-4 text-xs text-mountain-300 leading-relaxed">
                High-clearance 4x4 Jeeps and Prados engineered for unpaved river rock tracks in Ushu Forest and Kalam.
              </div>
            </div>

            <div className="group rounded-2xl bg-mountain-900 border border-mountain-800 hover:border-sky-500/50 overflow-hidden shadow-glass-sm transition-all duration-300 flex flex-col justify-between">
              <div className="h-44 bg-mountain-800 relative overflow-hidden">
                <img
                  src="/images/swat-student-van.jpg"
                  alt="Student School Transport"
                  className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-mountain-950 via-transparent to-transparent" />
                <span className="absolute bottom-3 left-3 px-2.5 py-1 text-xs font-bold rounded-md bg-sky-950/90 text-sky-300 border border-sky-500/30">
                  Student Ride School Van
                </span>
              </div>
              <div className="p-4 text-xs text-mountain-300 leading-relaxed">
                Dedicated monthly school transit with fixed background-checked drivers and authorized guardian handovers.
              </div>
            </div>

            <div className="group rounded-2xl bg-mountain-900 border border-mountain-800 hover:border-amber-500/50 overflow-hidden shadow-glass-sm transition-all duration-300 flex flex-col justify-between">
              <div className="h-44 bg-mountain-800 relative overflow-hidden">
                <img
                  src="/images/swat-cargo-truck.jpg"
                  alt="Cargo & Logistics Loader"
                  className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                />
                <div className="absolute inset-0 bg-gradient-to-t from-mountain-950 via-transparent to-transparent" />
                <span className="absolute bottom-3 left-3 px-2.5 py-1 text-xs font-bold rounded-md bg-amber-950/90 text-amber-300 border border-amber-500/30">
                  Cargo & Logistics Loader
                </span>
              </div>
              <div className="p-4 text-xs text-mountain-300 leading-relaxed">
                Express parcel pickups and heavy commercial loaders for retail, agricultural, and residential goods.
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ======================================================================
          2. CORE SERVICE SHOWCASE (6 Interactive 3D Service Cards)
         ====================================================================== */}
      <section id="services" className="relative py-16 sm:py-24 bg-mountain-900/40 border-t border-white/5">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <SectionHeader
            badge="The 6 Core Pillars"
            title="Explore the SWAT RIDE Mobility & Service Ecosystem"
            subtitle="Engineered specifically for the terrain, valleys, and daily life of Swat District. Select any service to explore transparent features and step-by-step guidance."
          />

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {SWAT_SERVICES.map((service) => (
              <ServiceCard3D key={service.id} service={service} />
            ))}
          </div>
        </div>
      </section>

      {/* ======================================================================
          3. HOW SWAT RIDE WORKS
         ====================================================================== */}
      <section className="relative py-16 sm:py-24">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <SectionHeader
            badge="Simple • Transparent • Reliable"
            title="How SWAT RIDE Works in 3 Easy Steps"
            subtitle="From upfront fare estimates in Mingora to mountain 4x4 Jeep confirmations in Kalam, booking is seamless."
          />

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 relative">
            {/* Step 1 */}
            <div className="relative p-8 rounded-2xl bg-mountain-900/80 border border-mountain-800 flex flex-col justify-between shadow-glass-sm">
              <div className="flex items-center justify-between mb-6">
                <span className="flex items-center justify-center w-12 h-12 rounded-xl bg-swat-600/20 text-swat-400 border border-swat-500/30 font-black text-lg">
                  01
                </span>
                <Navigation className="w-6 h-6 text-mountain-400" />
              </div>
              <div>
                <h3 className="text-xl font-bold text-white mb-2">
                  Select Service & Set Destination
                </h3>
                <p className="text-sm text-mountain-300 leading-relaxed">
                  Choose between Normal Ride, Food Delivery, Cargo, Student Ride, Hotels, or Tours. Enter your Swat location to view instant upfront fare estimates before confirming.
                </p>
              </div>
              <div className="mt-6 pt-4 border-t border-mountain-800/60 text-xs font-semibold text-swat-400">
                Transparent Pricing Guarantee
              </div>
            </div>

            {/* Step 2 */}
            <div className="relative p-8 rounded-2xl bg-mountain-900/80 border border-mountain-800 flex flex-col justify-between shadow-glass-sm">
              <div className="flex items-center justify-between mb-6">
                <span className="flex items-center justify-center w-12 h-12 rounded-xl bg-amber-500/20 text-amber-400 border border-amber-500/30 font-black text-lg">
                  02
                </span>
                <ShieldCheck className="w-6 h-6 text-mountain-400" />
              </div>
              <div>
                <h3 className="text-xl font-bold text-white mb-2">
                  Match with a Verified Local Partner
                </h3>
                <p className="text-sm text-mountain-300 leading-relaxed">
                  Our system connects you with background-checked local drivers, thermal-bag food riders, or certified 4x4 mountain tour guides in seconds.
                </p>
              </div>
              <div className="mt-6 pt-4 border-t border-mountain-800/60 text-xs font-semibold text-amber-400">
                CNIC & License Verified
              </div>
            </div>

            {/* Step 3 */}
            <div className="relative p-8 rounded-2xl bg-mountain-900/80 border border-mountain-800 flex flex-col justify-between shadow-glass-sm">
              <div className="flex items-center justify-between mb-6">
                <span className="flex items-center justify-center w-12 h-12 rounded-xl bg-sky-500/20 text-sky-400 border border-sky-500/30 font-black text-lg">
                  03
                </span>
                <Clock className="w-6 h-6 text-mountain-400" />
              </div>
              <div>
                <h3 className="text-xl font-bold text-white mb-2">
                  Track in Real-Time & Arrive Safely
                </h3>
                <p className="text-sm text-mountain-300 leading-relaxed">
                  Monitor GPS tracking on the map, share your trip status with family, and pay conveniently via cash on delivery or SWAT RIDE wallet.
                </p>
              </div>
              <div className="mt-6 pt-4 border-t border-mountain-800/60 text-xs font-semibold text-sky-400">
                24/7 SOS Support Included
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ======================================================================
          4. WHY SWAT RIDE (Trust & Local Differentiation)
         ====================================================================== */}
      <section className="relative py-16 sm:py-24 bg-gradient-to-b from-mountain-900/60 to-mountain-950 border-y border-white/5">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <SectionHeader
            badge="Why Swat Choose Us"
            title="Built by Swat, for Swat, with Zero Hidden Surprises"
            subtitle="We don’t rely on fake marketing claims or inflated statistics. We build genuine trust through rigorous safety, transparent pricing, and regional dedication."
          />

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
            <div className="p-6 rounded-2xl bg-mountain-900/50 border border-mountain-800 space-y-3">
              <div className="w-10 h-10 rounded-xl bg-swat-600/20 text-swat-400 border border-swat-500/30 flex items-center justify-center">
                <Wallet className="w-5 h-5" />
              </div>
              <h4 className="text-lg font-bold text-white">Upfront Fare Estimates</h4>
              <p className="text-sm text-mountain-300 leading-relaxed">
                Know your estimated ride fare before you book. No bargaining hassles in Mingora or surprise surcharges on mountain roads.
              </p>
            </div>

            <div className="p-6 rounded-2xl bg-mountain-900/50 border border-mountain-800 space-y-3">
              <div className="w-10 h-10 rounded-xl bg-amber-500/20 text-amber-400 border border-amber-500/30 flex items-center justify-center">
                <ShieldCheck className="w-5 h-5" />
              </div>
              <h4 className="text-lg font-bold text-white">Verified KPK Drivers</h4>
              <p className="text-sm text-mountain-300 leading-relaxed">
                Every driver undergoes strict background checks, CNIC verification, and vehicle safety audits at our Mingora regional office.
              </p>
            </div>

            <div className="p-6 rounded-2xl bg-mountain-900/50 border border-mountain-800 space-y-3">
              <div className="w-10 h-10 rounded-xl bg-red-600/20 text-red-400 border border-red-500/30 flex items-center justify-center">
                <ShieldAlert className="w-5 h-5" />
              </div>
              <h4 className="text-lg font-bold text-white">24/7 SOS & Privacy</h4>
              <p className="text-sm text-mountain-300 leading-relaxed">
                Dedicated emergency SOS button and Trusted Contacts trip sharing. We never conduct secret mic/camera monitoring without lawful authority.
              </p>
            </div>

            <div className="p-6 rounded-2xl bg-mountain-900/50 border border-mountain-800 space-y-3">
              <div className="w-10 h-10 rounded-xl bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 flex items-center justify-center">
                <Mountain className="w-5 h-5" />
              </div>
              <h4 className="text-lg font-bold text-white">4x4 Mountain Fleet</h4>
              <p className="text-sm text-mountain-300 leading-relaxed">
                Specialized 4x4 Jeeps and Prados equipped for Kalam, Ushu Forest, and Mahodand Lake with certified multilingual tour guides.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ======================================================================
          5. SAFETY & SOS CENTER PREVIEW
         ====================================================================== */}
      <section className="relative py-16 sm:py-24 overflow-hidden">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="p-8 sm:p-12 rounded-3xl bg-gradient-to-r from-mountain-900 via-mountain-950 to-red-950/40 border border-red-500/30 shadow-glass-lg">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
              <div className="lg:col-span-8 space-y-4">
                <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-red-600/20 border border-red-500/40 text-xs font-bold text-red-300 uppercase tracking-wider">
                  <ShieldAlert className="w-4 h-4" />
                  <span>SWAT RIDE Safety Center</span>
                </span>
                <h3 className="text-3xl sm:text-4xl font-extrabold text-white tracking-tight">
                  Your Safety & Privacy Are Never Compromised
                </h3>
                <p className="text-base text-mountain-300 leading-relaxed">
                  We believe real safety means verified local drivers, instant SOS emergency connectivity to our 24/7 Mingora desk, and Trusted Contacts trip sharing. We strictly respect KPK privacy laws and never claim or conduct secret device monitoring without proper legal authorization.
                </p>
                <div className="pt-2 flex flex-wrap gap-4">
                  <Link
                    href="/safety"
                    className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-red-600 hover:bg-red-500 text-white font-bold text-sm shadow-lg shadow-red-600/30 transition-all"
                  >
                    <span>Visit Full Safety & SOS Center</span>
                    <ArrowRight className="w-4 h-4" />
                  </Link>
                  <Link
                    href="/help/videos"
                    className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-white/10 hover:bg-white/15 text-white font-semibold text-sm border border-white/15 transition-all"
                  >
                    <span>Watch SOS Tutorial Video</span>
                  </Link>
                </div>
              </div>

              <div className="lg:col-span-4 flex items-center justify-center">
                <div className="p-6 rounded-2xl bg-mountain-950/80 border border-red-500/30 text-center space-y-3 w-full max-w-xs shadow-xl">
                  <div className="w-16 h-16 rounded-full bg-red-600 text-white flex items-center justify-center mx-auto shadow-lg shadow-red-600/50">
                    <ShieldAlert className="w-8 h-8" />
                  </div>
                  <h4 className="text-lg font-bold text-white">SOS Emergency</h4>
                  <p className="text-xs text-mountain-400">
                    One-tap live GPS alert to family & Mingora Safety Command Desk
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ======================================================================
          6. PARTNER WITH SWAT RIDE (9 Role Cards)
         ====================================================================== */}
      <section className="relative py-16 sm:py-24 bg-mountain-900/40 border-t border-white/5">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <SectionHeader
            badge="Empowering Swat & KPK"
            title="Partner With Us Across 9 Core Roles"
            subtitle="Whether you drive a car in Mingora, own a restaurant in Fiza Gat, manage hotel rooms in Malam Jabba, or lead 4x4 tours to Kalam, grow with SWAT RIDE."
          />

          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {PARTNER_ROLES.slice(0, 6).map((role) => (
              <div
                key={role.id}
                className="p-6 rounded-2xl bg-mountain-900/80 border border-mountain-800 hover:border-swat-500/50 transition-all duration-300 flex flex-col justify-between space-y-4"
              >
                <div>
                  <div className="flex items-center justify-between mb-4">
                    <span className="px-2.5 py-1 text-[11px] font-bold uppercase tracking-wider rounded-lg bg-swat-600/20 text-swat-300 border border-swat-500/30">
                      {role.category.toUpperCase()}
                    </span>
                    <span className="text-xs font-semibold text-mountain-400">Swat Region</span>
                  </div>
                  <h4 className="text-xl font-bold text-white mb-2">
                    {translateText(role.title, 'en')}
                  </h4>
                  <p className="text-sm text-mountain-300 leading-relaxed">
                    {translateText(role.subtitle, 'en')}
                  </p>
                </div>

                <div className="pt-4 border-t border-mountain-800/80 flex items-center justify-between">
                  <Link
                    href={`/${role.slug}`}
                    className="inline-flex items-center text-sm font-semibold text-swat-400 hover:text-swat-300 transition-colors"
                  >
                    <span>View Eligibility & Steps</span>
                    <ArrowRight className="w-4 h-4 ml-1" />
                  </Link>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-8 text-center">
            <Link
              href="/driver"
              className="inline-flex items-center gap-2 px-8 py-3.5 rounded-xl bg-mountain-800 hover:bg-mountain-700 text-white font-semibold text-sm border border-mountain-700 transition-colors"
            >
              <span>View All 9 Partner Roles (Drivers, Merchants, Guides & Parents)</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </section>

      {/* ======================================================================
          7. REWARDS & SWAT LOYALTY PREVIEW
         ====================================================================== */}
      <section className="relative py-16 sm:py-24">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="p-8 sm:p-12 rounded-3xl bg-gradient-to-r from-amber-950/40 via-mountain-900 to-mountain-950 border border-amber-500/30 shadow-glass-lg">
            <div className="flex flex-col lg:flex-row items-center justify-between gap-8">
              <div className="space-y-4 max-w-2xl text-center lg:text-left">
                <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/20 text-amber-300 border border-amber-500/30 text-xs font-bold uppercase tracking-wider">
                  <Gift className="w-4 h-4" />
                  <span>SWAT RIDE Loyalty & Promo Offers</span>
                </div>
                <h3 className="text-3xl sm:text-4xl font-extrabold text-white tracking-tight">
                  Earn Swat Points on Every Ride, Meal & Tour
                </h3>
                <p className="text-base text-mountain-300 leading-relaxed">
                  Every completed booking in the SWAT RIDE app automatically accumulates loyalty points. Redeem your points for ride credits, restaurant discounts, or hotel vouchers across Swat District.
                </p>
                <div className="pt-2 flex flex-wrap justify-center lg:justify-start gap-4">
                  <Link
                    href="/rewards"
                    className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-amber-500 hover:bg-amber-400 text-mountain-950 font-bold text-sm shadow-lg shadow-amber-500/30 transition-all"
                  >
                    <span>Explore Rewards Program</span>
                    <ArrowRight className="w-4 h-4" />
                  </Link>
                  <Link
                    href="/offers"
                    className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-white/10 hover:bg-white/15 text-white font-semibold text-sm border border-white/15 transition-all"
                  >
                    <span>View Current Promo Codes</span>
                  </Link>
                </div>
              </div>

              <div className="flex items-center justify-center">
                <div className="w-28 h-28 sm:w-36 sm:h-36 rounded-full bg-gradient-to-tr from-amber-500 to-yellow-300 flex items-center justify-center shadow-lg shadow-amber-500/40 border-4 border-amber-400/30">
                  <Gift className="w-16 h-16 text-mountain-950" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ======================================================================
          8. EXPLORE SWAT DESTINATIONS PREVIEW
         ====================================================================== */}
      <section className="relative py-16 sm:py-24 bg-mountain-900/40 border-y border-white/5">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <SectionHeader
            badge="Local KPK Destination Guides"
            title="Explore Swat Valley from Mingora to Mahodand Lake"
            subtitle="Discover accurate seasonal guides, road routes, and recommended transport tiers for Swat’s most breathtaking locations."
          />

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
            {SWAT_LOCATIONS.slice(0, 4).map((location) => (
              <div
                key={location.id}
                className="group relative rounded-2xl bg-mountain-900 border border-mountain-800 hover:border-swat-500/50 overflow-hidden shadow-glass-sm transition-all duration-300 flex flex-col justify-between"
              >
                <div className="h-44 bg-mountain-800 relative overflow-hidden">
                  <img
                    src={location.imageUrl}
                    alt={location.name}
                    className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
                  />
                  <div className="absolute inset-0 bg-gradient-to-t from-mountain-950 via-transparent to-transparent" />
                  <span className="absolute bottom-3 left-3 px-2.5 py-1 text-xs font-bold rounded-md bg-mountain-950/80 text-white border border-white/10 backdrop-blur-md">
                    {location.altitude}
                  </span>
                </div>

                <div className="p-5 space-y-2 flex-1 flex flex-col justify-between">
                  <div>
                    <div className="flex items-center justify-between">
                      <h4 className="text-lg font-bold text-white group-hover:text-swat-300 transition-colors">
                        {location.name}
                      </h4>
                      <span className="text-xs font-nastaliq text-mountain-400">
                        {location.urduName}
                      </span>
                    </div>
                    <p className="text-xs text-mountain-400 mt-1 line-clamp-2">
                      {location.tagline}
                    </p>
                  </div>

                  <div className="pt-3 border-t border-mountain-800/80">
                    <p className="text-[11px] text-swat-400 font-semibold mb-2">
                      Transport: {location.recommendedTransport}
                    </p>
                    <Link
                      href={`/blog`}
                      className="inline-flex items-center text-xs font-bold text-white hover:text-swat-300 transition-colors"
                    >
                      <span>Read {location.name} Guide</span>
                      <ArrowRight className="w-3.5 h-3.5 ml-1" />
                    </Link>
                  </div>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-8 text-center">
            <Link
              href="/blog"
              className="inline-flex items-center gap-2 px-8 py-3.5 rounded-xl bg-mountain-800 hover:bg-mountain-700 text-white font-semibold text-sm border border-mountain-700 transition-colors"
            >
              <span>View All Swat & KPK Destination Guides</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </section>

      {/* ======================================================================
          9. APP SCREENSHOTS / PRODUCT PRESENTATION
         ====================================================================== */}
      <section className="relative py-16 sm:py-24">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <SectionHeader
            badge="Engineered for Android"
            title="One Single App for Your Entire Swat Daily Life"
            subtitle="Built to perform smoothly on ordinary Android phones with fast loading, offline cached routes, and upfront fare transparency."
          />

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 items-center">
            <div className="p-8 rounded-2xl bg-mountain-900/80 border border-mountain-800 space-y-4">
              <div className="w-12 h-12 rounded-xl bg-swat-600/20 text-swat-400 flex items-center justify-center border border-swat-500/30">
                <Smartphone className="w-6 h-6" />
              </div>
              <h4 className="text-xl font-bold text-white">Low-Bandwidth Optimized</h4>
              <p className="text-sm text-mountain-300 leading-relaxed">
                Lightweight bundle footprint designed to load quickly even on 3G mobile data connections in remote Swat valleys.
              </p>
            </div>

            <div className="p-8 rounded-2xl bg-mountain-900/80 border border-mountain-800 space-y-4">
              <div className="w-12 h-12 rounded-xl bg-amber-500/20 text-amber-400 flex items-center justify-center border border-amber-500/30">
                <CheckCircle2 className="w-6 h-6" />
              </div>
              <h4 className="text-xl font-bold text-white">Upfront Fares & OTP Safety</h4>
              <p className="text-sm text-mountain-300 leading-relaxed">
                Review exact fare estimates before booking and confirm secure cargo or student handovers via digital OTP verification.
              </p>
            </div>

            <div className="p-8 rounded-2xl bg-mountain-900/80 border border-mountain-800 space-y-4">
              <div className="w-12 h-12 rounded-xl bg-sky-500/20 text-sky-400 flex items-center justify-center border border-sky-500/30">
                <Navigation className="w-6 h-6" />
              </div>
              <h4 className="text-xl font-bold text-white">Multilingual KPK Interface</h4>
              <p className="text-sm text-mountain-300 leading-relaxed">
                Switch effortlessly between English, Urdu, and Pashto inside the app for clear communication with local drivers and merchants.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ======================================================================
          10. LATEST USEFUL CONTENT (Blog Preview)
         ====================================================================== */}
      <section className="relative py-16 sm:py-24 bg-mountain-900/40 border-t border-white/5">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <SectionHeader
            badge="Travel & Safety Guides"
            title="Latest from the SWAT RIDE Knowledge Desk"
            subtitle="Explore human-authored, verified articles covering Kalam road routes, school transport safety standards, and Swat culinary highlights."
          />

          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {BLOG_ARTICLES.slice(0, 3).map((article) => (
              <Link
                key={article.id}
                href={`/blog/${article.slug}`}
                className="group flex flex-col justify-between rounded-2xl bg-mountain-900 border border-mountain-800 hover:border-swat-500/50 overflow-hidden shadow-glass-sm transition-all duration-300"
              >
                <div className="h-48 bg-mountain-800 overflow-hidden relative">
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
                    <h4 className="text-lg font-bold text-white group-hover:text-swat-300 transition-colors line-clamp-2">
                      {article.title}
                    </h4>
                    <p className="text-xs text-mountain-300 mt-2 line-clamp-3 leading-relaxed">
                      {article.excerpt}
                    </p>
                  </div>

                  <div className="pt-4 border-t border-mountain-800/80 flex items-center justify-between text-xs text-mountain-400">
                    <span>{article.author.name}</span>
                    <span>{article.readTime}</span>
                  </div>
                </div>
              </Link>
            ))}
          </div>

          <div className="mt-8 text-center">
            <Link
              href="/blog"
              className="inline-flex items-center gap-2 px-8 py-3.5 rounded-xl bg-mountain-800 hover:bg-mountain-700 text-white font-semibold text-sm border border-mountain-700 transition-colors"
            >
              <span>Explore All Swat Guides & Blog Articles</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </section>

      {/* ======================================================================
          11. FAQ PREVIEW SECTION
         ====================================================================== */}
      <section className="relative py-16 sm:py-24">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
          <SectionHeader
            badge="Common Questions"
            title="Frequently Asked Questions"
            subtitle="Get instant answers regarding upfront fare estimates, driver document verification, emergency SOS protocols, and 4x4 Kalam tours."
          />

          <div className="space-y-4">
            {HELP_ARTICLES.slice(0, 4).map((item) => {
              const isOpen = openFaq === item.id;
              const titleText = translateText(item.title, 'en');
              const contentText = translateText(item.content, 'en');

              return (
                <div
                  key={item.id}
                  className="rounded-2xl bg-mountain-900/80 border border-mountain-800 overflow-hidden transition-colors"
                >
                  <button
                    onClick={() => setOpenFaq(isOpen ? null : item.id)}
                    className="w-full flex items-center justify-between p-6 text-left focus:outline-none"
                    aria-expanded={isOpen}
                  >
                    <span className="text-base sm:text-lg font-bold text-white pr-4">
                      {titleText}
                    </span>
                    {isOpen ? (
                      <ChevronUp className="w-5 h-5 text-swat-400 shrink-0" />
                    ) : (
                      <ChevronDown className="w-5 h-5 text-mountain-400 shrink-0" />
                    )}
                  </button>
                  {isOpen && (
                    <div className="px-6 pb-6 text-sm text-mountain-300 leading-relaxed border-t border-mountain-800/60 pt-4">
                      {contentText}
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          <div className="mt-8 text-center">
            <Link
              href="/help"
              className="inline-flex items-center gap-2 px-8 py-3.5 rounded-xl bg-mountain-800 hover:bg-mountain-700 text-white font-semibold text-sm border border-mountain-700 transition-colors"
            >
              <HelpCircle className="w-4 h-4" />
              <span>Visit Full Help Center (18 Searchable Categories)</span>
            </Link>
          </div>
        </div>
      </section>

      {/* ======================================================================
          12. FINAL DOWNLOAD CTA
         ====================================================================== */}
      <CTASection />
    </div>
  );
}
