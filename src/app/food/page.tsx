'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import {
  Utensils,
  Store,
  Bike,
  Clock,
  CheckCircle2,
  DollarSign,
  Download,
  ArrowRight,
  ShieldCheck,
  Search,
  Star,
} from 'lucide-react';
import { Breadcrumbs } from '@/components/layout/Breadcrumbs';
import { SectionHeader } from '@/components/ui/SectionHeader';
import { CTASection } from '@/components/common/CTASection';
import { cn } from '@/lib/utils';

const DEMO_RESTAURANTS = [
  {
    id: 'trout-house-kalam',
    name: 'Swat River Trout House',
    cuisine: 'Fresh River Trout • Pashtun BBQ',
    area: 'Fiza Gat, Mingora',
    deliveryTime: '25-35 min',
    image: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?auto=format&fit=crop&w=600&q=80',
    featured: 'Grilled Brown Trout with Garlic Lemon',
  },
  {
    id: 'mingora-kebab-palace',
    name: 'Mingora Kebab & Dum Pukht Palace',
    cuisine: 'Authentic Chapli Kebab • Mutton Karahi',
    area: 'Mingora Bazaar',
    deliveryTime: '20-30 min',
    image: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=600&q=80',
    featured: 'Special Beef Chapli Kebab (2 Pcs)',
  },
  {
    id: 'saidu-family-diner',
    name: 'Saidu Sharif Family Eatery',
    cuisine: 'Pakistani Traditional • Continental',
    area: 'Saidu Sharif',
    deliveryTime: '15-25 min',
    image: 'https://images.unsplash.com/photo-1544025162-d76694265947?auto=format&fit=crop&w=600&q=80',
    featured: 'Chicken Handi & Hot Naan Platter',
  },
];

export default function FoodServicePage() {
  const [filter, setFilter] = useState('all');

  const foodSteps = [
    {
      step: '01',
      title: 'Restaurant Discovery',
      desc: 'Browse verified restaurants across Mingora, Saidu Sharif, and Fiza Gat filtered by cuisine and delivery time.',
    },
    {
      step: '02',
      title: 'Menu Exploration & Cart',
      desc: 'Select item variations, add special preparation notes, and review transparent itemized cart totals.',
    },
    {
      step: '03',
      title: 'Order & Flexible Payment',
      desc: 'Confirm your order and pay via cash on delivery or digital SWAT RIDE wallet balance with zero hidden fees.',
    },
    {
      step: '04',
      title: 'Real-Time Kitchen Preparation',
      desc: 'Track order progress from order acceptance to kitchen preparation and packaging.',
    },
    {
      step: '05',
      title: 'Dedicated Rider Assignment',
      desc: 'An approved SWAT RIDE food delivery rider arrives at the restaurant equipped with thermal-insulated bags.',
    },
    {
      step: '06',
      title: 'Live Map Tracking & Delivery',
      desc: 'Monitor your food rider on the live GPS map as your meal is delivered hot right to your doorstep.',
    },
  ];

  return (
    <div className="relative py-12 sm:py-16">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <Breadcrumbs
          items={[
            { label: 'Services', href: '/#services' },
            { label: 'Food Delivery' },
          ]}
        />

        {/* Hero Banner */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center mb-20">
          <div className="lg:col-span-7 space-y-6">
            <span className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-amber-950/80 border border-amber-500/40 text-xs font-semibold text-amber-300">
              <Utensils className="w-4 h-4 text-amber-400" />
              <span>SWAT RIDE • Food Delivery Service</span>
            </span>

            <h1 className="text-4xl sm:text-5xl font-black text-white tracking-tight leading-tight">
              Hot Swati Trout & Local Specialties Delivered{' '}
              <span className="bg-gradient-to-r from-amber-400 to-yellow-300 bg-clip-text text-transparent">
                Fresh & Fast
              </span>
            </h1>

            <p className="text-base sm:text-lg text-mountain-300 leading-relaxed max-w-2xl">
              From river-fresh brown trout in Fiza Gat to Chapli Kebabs in Mingora Bazaar, enjoy authentic local delicacies delivered in thermal-insulated bags by verified riders.
            </p>

            <div className="flex flex-col sm:flex-row items-center gap-4 pt-2">
              <Link
                href="/download"
                className="inline-flex items-center justify-center gap-2.5 px-8 py-4 rounded-2xl bg-amber-500 hover:bg-amber-400 text-mountain-950 font-bold text-base shadow-lg shadow-amber-500/30 transition-all w-full sm:w-auto"
              >
                <Download className="w-5 h-5" />
                <span>Order Food in App</span>
              </Link>
              <Link
                href="/restaurant-partner"
                className="inline-flex items-center justify-center gap-2 px-8 py-4 rounded-2xl bg-white/10 hover:bg-white/15 text-white font-semibold text-base border border-white/15 transition-all w-full sm:w-auto"
              >
                <span>Partner Your Restaurant</span>
                <ArrowRight className="w-4 h-4" />
              </Link>
            </div>
          </div>

          {/* Right: Restaurant Discovery Showcase */}
          <div className="lg:col-span-5">
            <div className="p-6 rounded-3xl bg-mountain-900 border border-mountain-800 shadow-glass-lg space-y-4">
              <div className="flex items-center justify-between border-b border-mountain-800 pb-3">
                <h3 className="text-base font-bold text-white">Popular Swat Eateries</h3>
                <span className="text-xs text-amber-400 font-semibold">Live in App</span>
              </div>

              <div className="space-y-4">
                {DEMO_RESTAURANTS.map((resto) => (
                  <div
                    key={resto.id}
                    className="flex items-center gap-4 p-3 rounded-2xl bg-mountain-950/80 border border-mountain-800 hover:border-amber-500/40 transition-all"
                  >
                    <img
                      src={resto.image}
                      alt={resto.name}
                      className="w-16 h-16 rounded-xl object-cover shrink-0"
                    />
                    <div className="flex-1 min-w-0">
                      <h4 className="text-sm font-bold text-white truncate">{resto.name}</h4>
                      <p className="text-xs text-mountain-400 truncate">{resto.cuisine}</p>
                      <div className="flex items-center gap-2 mt-1 text-[11px] text-amber-400 font-semibold">
                        <Clock className="w-3.5 h-3.5" />
                        <span>{resto.deliveryTime}</span>
                        <span>•</span>
                        <span>{resto.area}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>

              <div className="text-center pt-2">
                <Link
                  href="/download"
                  className="inline-flex items-center gap-1.5 text-xs font-bold text-amber-400 hover:text-amber-300 transition-colors"
                >
                  <span>View Full Menu & Prices in App</span>
                  <ArrowRight className="w-3.5 h-3.5" />
                </Link>
              </div>
            </div>
          </div>
        </div>

        {/* 10 Step Workflow Grid */}
        <SectionHeader
          badge="From Kitchen to Doorstep"
          title="The 10-Stage Verified Food Delivery Journey"
          subtitle="We ensure total hygiene, thermal temperature preservation, and transparent pricing on every order."
        />

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-20">
          {foodSteps.map((step, idx) => (
            <div
              key={idx}
              className="p-6 rounded-2xl bg-mountain-900/80 border border-mountain-800 space-y-3"
            >
              <div className="flex items-center justify-between">
                <span className="text-sm font-black text-amber-400 font-mono">STEP {step.step}</span>
                <CheckCircle2 className="w-5 h-5 text-amber-400" />
              </div>
              <h3 className="text-lg font-bold text-white">{step.title}</h3>
              <p className="text-sm text-mountain-300 leading-relaxed">{step.desc}</p>
            </div>
          ))}
        </div>

        {/* Bottom Dual Partner CTA */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div className="p-8 rounded-3xl bg-gradient-to-br from-mountain-900 to-mountain-950 border border-mountain-800 space-y-4">
            <Store className="w-10 h-10 text-amber-400" />
            <h3 className="text-2xl font-bold text-white">Own a Restaurant in Swat?</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              Expand your sales without building a separate delivery fleet. Get featured on SWAT RIDE Food with transparent weekly settlements.
            </p>
            <Link
              href="/restaurant-partner"
              className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-amber-500 text-mountain-950 font-bold text-sm transition-all"
            >
              <span>Register Your Restaurant</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>

          <div className="p-8 rounded-3xl bg-gradient-to-br from-mountain-900 to-mountain-950 border border-mountain-800 space-y-4">
            <Bike className="w-10 h-10 text-swat-400" />
            <h3 className="text-2xl font-bold text-white">Become a Food Delivery Rider</h3>
            <p className="text-sm text-mountain-300 leading-relaxed">
              Have a motorcycle in Mingora? Earn competitive delivery fees with short-distance localized orders and thermal-bag gear.
            </p>
            <Link
              href="/food-rider"
              className="inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-swat-600 text-white font-bold text-sm transition-all"
            >
              <span>Apply as Food Rider</span>
              <ArrowRight className="w-4 h-4" />
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
