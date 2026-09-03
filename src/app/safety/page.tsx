'use client';

import React from 'react';
import Link from 'next/link';
import {
  ShieldAlert,
  ShieldCheck,
  UserCheck,
  Radio,
  Lock,
  PhoneCall,
  Bell,
  CheckCircle2,
  AlertTriangle,
  Download,
  ArrowRight,
  FileText,
  HelpCircle,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { CTASection } from '@/components/common/CTASection';
import { cn } from '@/lib/utils';

export default function SafetyCenterPage() {
  const safetyAreas = [
    {
      title: '1. Verified SOS Emergency Button',
      desc: 'One-tap emergency SOS connection in the app that instantly transmits your GPS coordinates and trip details to your Trusted Contacts and our 24/7 Mingora Safety Command Desk.',
      icon: <ShieldAlert className="w-6 h-6 text-red-400" />,
    },
    {
      title: '2. Trusted Contacts & Trip Sharing',
      desc: 'Pre-configure family members or friends in your app profile. Share a real-time live GPS web link so they can monitor your ride from pickup to destination.',
      icon: <Radio className="w-6 h-6 text-red-400" />,
    },
    {
      title: '3. Driver Background & CNIC Audits',
      desc: 'Every driver across Swat must submit original CNIC, valid KPK driving license, vehicle documents, and police character verification prior to activation.',
      icon: <UserCheck className="w-6 h-6 text-red-400" />,
    },
    {
      title: '4. Student Ride Authorized Handover',
      desc: 'In our school transport service, drivers only release children to authorized guardians registered with photo ID. No child is ever left unattended.',
      icon: <Lock className="w-6 h-6 text-red-400" />,
    },
    {
      title: '5. Food & Cargo Chain-of-Custody',
      desc: 'Insulated thermal food bags keep meals hygienic, while cargo deliveries require digital OTP verification from the recipient at drop-off.',
      icon: <CheckCircle2 className="w-6 h-6 text-red-400" />,
    },
    {
      title: '6. 4x4 Mountain Tourism Safety',
      desc: 'All 4x4 vehicles operating on high-altitude Kalam and Mahodand Lake routes undergo mechanical brake inspections and regional trail safety checks.',
      icon: <AlertTriangle className="w-6 h-6 text-red-400" />,
    },
  ];

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Safety & Support', href: '/safety' },
            { label: 'SWAT RIDE Safety Center' },
          ]}
        />

        {/* Hero Section */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center mb-20">
          <div className="lg:col-span-8 space-y-6">
            <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-red-950/80 border border-red-500/40 text-xs font-semibold text-red-300">
              <ShieldAlert className="w-4 h-4 text-red-400" />
              <span>SWAT RIDE • Verified Safety & Privacy</span>
            </span>

            <h1 className="text-4xl sm:text-5xl lg:text-6xl font-black text-white tracking-tight leading-tight">
              Safety Is Our Uncompromising{' '}
              <span className="bg-gradient-to-r from-red-400 via-rose-300 to-amber-300 bg-clip-text text-transparent">
                Obligation
              </span>
            </h1>

            <p className="text-base sm:text-lg text-mountain-300 leading-relaxed max-w-3xl">
              We build real safety through rigorous driver vetting, verified emergency SOS connectivity, and transparent family trip sharing. We never make impossible marketing promises or conduct secret device monitoring.
            </p>

            {/* Crucial Privacy & Lawful Authority Notice */}
            <div className="p-5 rounded-2xl bg-mountain-900 border-2 border-red-500/40 text-xs sm:text-sm text-red-200 space-y-2">
              <div className="flex items-center gap-2 font-bold text-white uppercase tracking-wider">
                <ShieldCheck className="w-5 h-5 text-red-400" />
                <span>Verified Privacy Commitment</span>
              </div>
              <p className="leading-relaxed">
                SWAT RIDE strictly obeys Khyber Pakhtunkhwa and Pakistani data privacy laws. We <strong className="text-white">DO NOT</strong> secretly activate any user’s camera, microphone, device storage, or background location without explicit legal authorization or direct user-granted permission.
              </p>
            </div>

            <div className="flex flex-col sm:flex-row items-center gap-4 pt-2">
              <Link
                href="/download"
                className="inline-flex items-center justify-center gap-2.5 px-8 py-4 rounded-2xl bg-red-600 hover:bg-red-500 text-white font-bold text-base shadow-lg shadow-red-600/30 transition-all w-full sm:w-auto"
              >
                <Download className="w-5 h-5" />
                <span>Configure Safety in App</span>
              </Link>
              <Link
                href="/help/videos"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl bg-white/10 hover:bg-white/15 text-white font-semibold text-base border border-white/15 transition-all w-full sm:w-auto"
              >
                <span>Watch SOS Video Tutorial</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          {/* Right Safety Emblem */}
          <div className="lg:col-span-4 flex items-center justify-center">
            <div className="p-8 rounded-3xl bg-gradient-to-br from-mountain-900 via-mountain-950 to-red-950/50 border border-red-500/30 shadow-glass-lg text-center space-y-4 w-full max-w-xs">
              <div className="w-20 h-20 rounded-2xl bg-red-600/20 text-red-400 border border-red-500/30 flex items-center justify-center mx-auto shadow-glow-emerald">
                <ShieldAlert className="w-10 h-10" />
              </div>
              <h3 className="text-xl font-bold text-white">24/7 Command Desk</h3>
              <p className="text-xs text-mountain-400">
                Central Mingora Safety Office • Continuous trip monitoring and emergency responder coordination
              </p>
            </div>
          </div>
        </div>

        {/* 6 Comprehensive Safety Pillars */}
        <SectionHeader
          badge="End-to-End Protocols"
          title="How We Protect Passengers, Students & Drivers"
          subtitle="Real safety requires proactive verification, transparent tracking, and clear operational discipline."
        />

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-20">
          {safetyAreas.map((area, idx) => (
            <div
              key={idx}
              className="p-8 rounded-3xl bg-mountain-900/80 border border-mountain-800 hover:border-red-500/40 transition-all space-y-4"
            >
              <div className="w-12 h-12 rounded-xl bg-red-600/20 text-red-400 border border-red-500/30 flex items-center justify-center">
                {area.icon}
              </div>
              <h3 className="text-xl font-bold text-white">{area.title}</h3>
              <p className="text-sm text-mountain-300 leading-relaxed">{area.desc}</p>
            </div>
          ))}
        </div>

        {/* Safety Report / Contact Support CTA */}
        <div className="p-8 sm:p-12 rounded-3xl bg-gradient-to-r from-mountain-900 via-mountain-950 to-red-950/40 border border-red-500/30 shadow-glass-lg flex flex-col sm:flex-row items-center justify-between gap-8">
          <div className="space-y-2 text-center sm:text-left">
            <h3 className="text-2xl font-bold text-white">Have a Safety Concern or Report?</h3>
            <p className="text-sm text-mountain-300 max-w-xl">
              Our safety desk reviews all reports regarding driver conduct, route safety, or app security within 2 hours. Your identity is always kept strictly confidential.
            </p>
          </div>
          <Link
            href="/contact"
            className="inline-flex items-center gap-2 px-8 py-4 rounded-2xl bg-red-600 hover:bg-red-500 text-white font-bold text-sm shadow-lg shadow-red-600/30 transition-all shrink-0"
          >
            <span>Submit Safety Feedback</span>
            <ArrowRight className="w-4 h-4" />
          </Link>
        </div>
      </div>
    </div>
  );
}
