'use client';

import React from 'react';
import Link from 'next/link';
import { RefreshCw, AlertCircle, ShieldCheck } from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';

export default function RefundPolicyPage() {
  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Legal & Privacy', href: '/refund-policy' },
            { label: 'Refund Policy' },
          ]}
        />

        <div className="p-4 rounded-2xl bg-amber-950/80 border border-amber-500/40 text-xs text-amber-200 flex items-start gap-3 mb-8">
          <AlertCircle className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
          <div>
            <span className="font-bold uppercase tracking-wider block text-white">
              LEGAL REVIEW NOTICE
            </span>
            <span>
              This refund policy requires formal review by certified legal counsel in Khyber Pakhtunkhwa, Pakistan prior to formal commercial launch.
            </span>
          </div>
        </div>

        <div className="space-y-6 mb-12">
          <h1 className="text-4xl font-black text-white tracking-tight">
            SWAT RIDE Refund Policy
          </h1>
          <p className="text-sm text-mountain-400">
            Last Updated: August 11, 2026 • Transparent Settlement Rules
          </p>
        </div>

        <div className="prose prose-invert prose-emerald max-w-none space-y-8 text-mountain-200 text-sm leading-relaxed">
          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">1. Ride Fares & Wallet Refunds</h2>
            <p>
              If a Normal Ride or Cargo trip is cancelled by the driver after confirmation without passenger fault, any prepaid wallet balance is refunded instantly to your SWAT RIDE wallet. If you believe an upfront fare was mischarged due to GPS error, submit a ticket within 48 hours for full investigation and wallet credit adjustment.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">2. Food Delivery Quality Refunds</h2>
            <p>
              If a food delivery order arrives incomplete, spilled, or significantly damaged, report the order with photo evidence through our Support Desk within 2 hours. Verified claims receive a 100% item refund or replacement credit.
            </p>
          </section>

          <section className="space-y-3">
            <h2 className="text-xl font-bold text-white">3. Hotel & Tour Package Refunds</h2>
            <p>
              Hotel bookings and 4x4 Kalam mountain tour packages follow clearly published property cancellation rules. Generally, cancellations made 48 hours prior to check-in receive a full refund minus standard bank processing charges.
            </p>
          </section>
        </div>
      </div>
    </div>
  );
}
