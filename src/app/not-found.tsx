'use client';

import React from 'react';
import Link from 'next/link';
import { AlertCircle, Home, HelpCircle, ArrowLeft } from 'lucide-react';

export default function NotFoundPage() {
  return (
    <div className="min-h-[70vh] flex items-center justify-center p-6 text-center">
      <div className="max-w-md mx-auto space-y-6">
        <div className="w-20 h-20 rounded-3xl bg-red-600/20 text-red-400 border border-red-500/30 flex items-center justify-center mx-auto shadow-glass-md">
          <AlertCircle className="w-10 h-10" />
        </div>

        <div className="space-y-2">
          <span className="text-sm font-bold text-swat-400 font-mono tracking-wider">
            ERROR 404 • NOT FOUND
          </span>
          <h1 className="text-3xl sm:text-4xl font-black text-white tracking-tight">
            Page Not Found
          </h1>
          <p className="text-sm text-mountain-300 leading-relaxed">
            The page or route you are looking for does not exist or has been moved in the SWAT RIDE ecosystem.
          </p>
        </div>

        <div className="flex flex-col sm:flex-row items-center justify-center gap-3 pt-2">
          <Link
            href="/"
            className="inline-flex items-center justify-center gap-2 px-6 py-3 rounded-xl bg-swat-600 hover:bg-swat-500 text-white text-sm font-bold shadow-lg shadow-swat-600/30 transition-all w-full sm:w-auto"
          >
            <Home className="w-4 h-4" />
            <span>Back to Home</span>
          </Link>

          <Link
            href="/help"
            className="inline-flex items-center justify-center gap-2 px-6 py-3 rounded-xl bg-white/10 hover:bg-white/15 text-white text-sm font-semibold border border-white/15 transition-all w-full sm:w-auto"
          >
            <HelpCircle className="w-4 h-4" />
            <span>Visit Help Center</span>
          </Link>
        </div>
      </div>
    </div>
  );
}
