import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}

/**
 * Validates external URL strings and sanitizes user input
 */
export function sanitizeInput(input: string, maxLength = 500): string {
  if (!input || typeof input !== 'string') return '';
  return input
    .trim()
    .slice(0, maxLength)
    .replace(/[<>]/g, '');
}

/**
 * Safe helper to trigger privacy-conscious analytics events
 */
export function trackEvent(eventName: string, properties?: Record<string, string | number | boolean>) {
  if (typeof window === 'undefined') return;
  
  // Custom console debug in development, ready for GA4 in production
  if (process.env.NODE_ENV !== 'production') {
    console.debug(`[SWAT RIDE Analytics] Event: ${eventName}`, properties);
  } else if (typeof (window as any).gtag === 'function') {
    (window as any).gtag('event', eventName, properties);
  }
}

/**
 * Format currency in Pakistani Rupees (PKR)
 */
export function formatPKR(amount: number): string {
  return new Intl.NumberFormat('en-PK', {
    style: 'currency',
    currency: 'PKR',
    maximumFractionDigits: 0,
  }).format(amount);
}
