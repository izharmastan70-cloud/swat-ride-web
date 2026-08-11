'use client';

import React from 'react';
import Link from 'next/link';
import { AlertCircle, RefreshCw } from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';

export default function CancellationPolicyPage() {
  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Legal & Privacy', href: '/cancellation-policy' },
            { label: 'Cancellation Policy' },
          ]}
        />

        <div className="p-4 rounded-2xl bg-amber-950/80 border border-amber-500/40 text-xs text-amber-200 flex items-start gap-3 mb-8">
          <AlertCircle className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
          <div>
            <span className="font-bold uppercase tracking-wider block text-white">
              LEGAL REVIEW NOTICE
            </span>
            <span>
              This cancellation policy requires formal review by certified legal counsel in Khyber Pakhtunkhwa, Pakistan prior to formal commercial launch.
            </span>
          </div>
        </div>

        <div className="space-y-6 mb-12">
          <h1 className="text-4xl font-black text-white tracking-tight">
            SWAT RIDE Cancellation Policy
          </h1>
          <p className="text-sm text-mountain-400">
            Last Updated: August 11, 2026 • Transparent Cancellation Terms
          </p>
        </div>

        <div className="prose prose-invert prose-emerald max-w-none space-y-8 text-mountain-200 text-sm leading-relaxed">
          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">1. Normal Ride & Cargo Cancellations</h2>
            <p>
              Passengers may cancel a ride booking free of charge within 2 minutes of driver matching. Cancellations made after a driver has arrived at the pickup location in Swat may incur a modest cancellation fee to compensate the driver for fuel and travel time.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">2. Food Order Cancellations</h2>
            <p>
              Food orders can be cancelled without charge before the restaurant partner accepts and begins kitchen preparation. Once kitchen preparation commences, cancellation requests cannot be accepted.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">3. School Transport Monthly Subscriptions</h2>
            <p>
              Parents may modify or cancel a monthly Student Ride package with 7 days advance notice prior to the next billing cycle. No hidden cancellation penalties are applied.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
