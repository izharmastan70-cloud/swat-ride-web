'use client';

import React from 'react';
import Link from 'next/link';
import {
  GraduationCap,
  ShieldCheck,
  UserCheck,
  Bell,
  Lock,
  Calendar,
  ShieldAlert,
  Download,
  ArrowRight,
  CheckCircle2,
  Heart,
  Home,
  Clock,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { CTASection } from '@/components/common/CTASection';
import { cn } from '@/lib/utils';

export default function StudentRidePage() {
  const safetyPillars = [
    {
      title: 'Dedicated Monthly Package with Fixed Vetted Driver',
      desc: 'Your child travels with the same background-checked driver every day. No random drivers or changing vehicles.',
      icon: <UserCheck className="w-6 h-6 text-emerald-400" />,
    },
    {
      title: 'Authorized Guardian Handover Protocol',
      desc: 'Drivers only release children to authorized drop-off guardians registered in the app with photo ID verification.',
      icon: <Lock className="w-6 h-6 text-emerald-400" />,
    },
    {
      title: 'Real-Time Daily Attendance Notifications',
      desc: 'Receive timestamped alerts when your child boards from home, enters the school gates, and returns safely.',
      icon: <Bell className="w-6 h-6 text-emerald-400" />,
    },
    {
      title: 'Direct SOS Link to Parent & Safety Command Desk',
      desc: 'Every trip features 24/7 SOS monitoring. In case of any traffic delay or issue, parents are updated immediately.',
      icon: <ShieldAlert className="w-6 h-6 text-red-400" />,
    },
  ];

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Services', href: '/#services' },
            { label: 'Student Ride & School Transport' },
          ]}
        />

        {/* Hero Section - Trust-Focused Design */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center mb-20">
          <div className="lg:col-span-7 space-y-6">
            <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-950/80 border border-emerald-500/40 text-xs font-semibold text-emerald-300">
              <GraduationCap className="w-4 h-4 text-emerald-400" />
              <span>SWAT RIDE • School Transport & Parent Trust</span>
            </span>

            <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight leading-tight">
              Trust-First Monthly School Transport in{' '}
              <span className="bg-gradient-to-r from-emerald-400 to-teal-300 bg-clip-text text-transparent">
                Swat District
              </span>
            </h1>

            <p className="text-base sm:text-lg text-mountain-300 leading-relaxed max-w-2xl">
              Engineered for parental peace of mind across Mingora, Saidu Sharif, and Qambar. With background-checked fixed drivers, authorized guardian handovers, and real-time attendance alerts, your child is in safe hands.
            </p>

            <div className="flex flex-col sm:flex-row items-center gap-4 pt-2">
              <Link
                href="/download"
                className="inline-flex items-center justify-center gap-2.5 px-8 py-4 rounded-2xl bg-emerald-600 hover:bg-emerald-500 text-white font-bold text-base shadow-lg shadow-emerald-600/30 transition-all w-full sm:w-auto"
              >
                <Download className="w-5 h-5" />
                <span>Enroll Student in App</span>
              </Link>
              <Link
                href="/parents"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl bg-white/10 hover:bg-white/15 text-white font-semibold text-base border border-white/15 transition-all w-full sm:w-auto"
              >
                <span>Parent Portal Setup Guide</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          {/* Right: Daily Transit Workflow Card */}
          <div className="lg:col-span-5">
            <div className="p-6 sm:p-8 rounded-3xl bg-gradient-to-br from-mountain-900 via-mountain-950 to-emerald-950/40 border border-emerald-500/30 shadow-glass-lg space-y-6">
              <div className="flex items-center justify-between border-b border-mountain-800 pb-4">
                <h3 className="text-lg font-bold text-white">Daily Transit Protocol</h3>
                <span className="text-xs text-emerald-400 font-semibold uppercase">Parent Alert Demo</span>
              </div>

              <div className="space-y-4">
                <div className="flex items-start gap-4 p-3.5 rounded-2xl bg-mountain-950/80 border border-emerald-500/20">
                  <div className="p-2 rounded-lg bg-emerald-500/20 text-emerald-400">
                    <Home className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="flex items-center justify-between">
                      <h4 className="text-sm font-bold text-white">07:30 AM — Home Pickup</h4>
                      <span className="text-[10px] text-emerald-400 font-semibold">VERIFIED</span>
                    </div>
                    <p className="text-xs text-mountain-400 mt-0.5">
                      Fixed driver Tariq Khan boards student at Mingora doorstep.
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-4 p-3.5 rounded-2xl bg-mountain-950/80 border border-emerald-500/20">
                  <div className="p-2 rounded-lg bg-emerald-500/20 text-emerald-400">
                    <GraduationCap className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="flex items-center justify-between">
                      <h4 className="text-sm font-bold text-white">07:50 AM — School Drop</h4>
                      <span className="text-[10px] text-emerald-400 font-semibold">VERIFIED</span>
                    </div>
                    <p className="text-xs text-mountain-400 mt-0.5">
                      Student safely arrives at Saidu Sharif High School gate.
                    </p>
                  </div>
                </div>

                <div className="flex items-start gap-4 p-3.5 rounded-2xl bg-mountain-950/80 border border-emerald-500/20">
                  <div className="p-2 rounded-lg bg-emerald-500/20 text-emerald-400">
                    <Lock className="w-5 h-5" />
                  </div>
                  <div>
                    <div className="flex items-center justify-between">
                      <h4 className="text-sm font-bold text-white">02:10 PM — Guardian Handover</h4>
                      <span className="text-[10px] text-emerald-400 font-semibold">VERIFIED</span>
                    </div>
                    <p className="text-xs text-mountain-400 mt-0.5">
                      Driver confirms authorized guardian photo ID before releasing child.
                    </p>
                  </div>
                </div>
              </div>

              <div className="text-center pt-2">
                <p className="text-[11px] text-mountain-400">
                  *All student routes are monitored by our 24/7 Mingora Safety Desk.
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Trust Pillars Grid */}
        <SectionHeader
          badge="Uncompromising Security"
          title="Why Swat Parents Trust Our School Transport"
          subtitle="We never compromise on safety. Discover our 4 trust-first operational standards."
        />

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8 mb-20">
          {safetyPillars.map((pillar, idx) => (
            <div
              key={idx}
              className="p-8 rounded-3xl bg-mountain-900/80 border border-mountain-800 hover:border-emerald-500/40 transition-all flex items-start gap-6"
            >
              <div className="p-3 rounded-2xl bg-mountain-950 border border-mountain-800 shrink-0">
                {pillar.icon}
              </div>
              <div className="space-y-2">
                <h3 className="text-xl font-bold text-white">{pillar.title}</h3>
                <p className="text-sm text-mountain-300 leading-relaxed">{pillar.desc}</p>
              </div>
            </div>
          ))}
        </div>

        {/* Driver / Parent CTA */}
        <CTASection
          title="Set Up Monthly School Transport for Your Child Today"
          subtitle="Download the app to register your child’s school timetable and authorize trusted drop-off guardians."
          primaryCtaText="Enroll in App"
          primaryCtaLink="/download"
          secondaryCtaText="Become a Student Driver"
          secondaryCtaLink="/student-driver"
        />
      </div>
    </div>
  );
}
