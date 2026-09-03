'use client';

import React from 'react';
import Link from 'next/link';
import {
  ShieldAlert,
  ShieldCheck,
  Lock,
  Eye,
  FileText,
  AlertCircle,
  CheckCircle2,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';

export default function PrivacyPolicyPage() {
  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Legal & Privacy', href: '/privacy' },
            { label: 'Privacy Policy' },
          ]}
        />

        {/* Legal Human Review Banner */}
        <div className="p-4 rounded-2xl bg-amber-950/80 border border-amber-500/40 text-xs text-amber-200 flex items-start gap-3 mb-8">
          <AlertCircle className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
          <div>
            <span className="font-bold uppercase tracking-wider block text-white">
              LEGAL REVIEW NOTICE
            </span>
            <span>
              This privacy document is structured for the SWAT RIDE platform and requires final review by certified legal counsel in Khyber Pakhtunkhwa, Pakistan prior to formal commercial launch.
            </span>
          </div>
        </div>

        <div className="space-y-6 mb-12">
          <h1 className="text-4xl font-black text-white tracking-tight">
            SWAT RIDE Privacy Policy
          </h1>
          <p className="text-sm text-mountain-400">
            Last Updated: August 11, 2026 • Effective Date: Upon Official Google Play Launch
          </p>
        </div>

        {/* Crucial Device Monitoring Commitment */}
        <div className="p-6 rounded-2xl bg-mountain-900 border-2 border-red-500/40 text-sm text-red-200 space-y-3 mb-10">
          <div className="flex items-center gap-2 font-bold text-white uppercase tracking-wider">
            <ShieldCheck className="w-5 h-5 text-red-400" />
            <span>Core Privacy & Device Integrity Commitment</span>
          </div>
          <p className="leading-relaxed">
            SWAT RIDE strictly adheres to Khyber Pakhtunkhwa and Pakistani data protection laws. We <strong className="text-white">DO NOT</strong> secretly activate any user’s camera, microphone, device storage, or background location without lawful judicial authority or explicit user-granted permission. We never market impossible or unimplemented surveillance functionality.
          </p>
        </div>

        {/* Body Sections */}
        <div className="prose prose-invert prose-emerald max-w-none space-y-8 text-mountain-200 text-sm leading-relaxed">
          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">1. Information We Collect</h2>
            <p>
              When you register or use the SWAT RIDE Android application in Swat, KPK, we collect essential service data required to operate mobility, food delivery, cargo logistics, school transport, and tourism features:
            </p>
            <ul className="list-disc pl-5 space-y-1">
              <li>
                <strong className="text-white">Account Information:</strong> Your name, phone number, language preference (English, Urdu, Pashto), and emergency Trusted Contacts.
              </li>
              <li>
                <strong className="text-white">Location Data:</strong> GPS coordinates during active ride booking, food delivery tracking, or school transit to provide upfront fare estimates and driver matching.
              </li>
              <li>
                <strong className="text-white">Partner & Driver Verification:</strong> Original CNIC numbers, KPK driving licenses, vehicle registration books, and security verification certificates for partner approval.
              </li>
            </ul>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">2. How We Use Your Data</h2>
            <p>
              Your data is used strictly for operational platform performance, passenger safety, and customer support:
            </p>
            <ul className="list-disc pl-5 space-y-1">
              <li>Matching passengers in Mingora and Swat with verified local drivers.</li>
              <li>Transmitting emergency SOS alerts to your Trusted Contacts and our 24/7 Mingora Safety Desk.</li>
              <li>Generating transparent financial settlements and commission reports for drivers and restaurant partners.</li>
            </ul>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">3. Analytics & Advertising Consent</h2>
            <p>
              We use privacy-conscious aggregate analytics to monitor LCP/INP performance on 3G cellular networks in Swat. We never sell personal identity data to third-party data brokers. Future sponsored travel listings or display ads will never obstruct emergency SOS or critical safety flows.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">4. Your Data Rights & Contact</h2>
            <p>
              You have the right to request access, correction, or deletion of your SWAT RIDE profile at any time through our Support Desk. For privacy inquiries, contact <strong className="text-white">privacy@swatride.pk</strong> or visit our regional office in Mingora, Swat.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
