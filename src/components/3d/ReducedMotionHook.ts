'use client';

import { useState, useEffect } from 'react';

/**
 * Detects prefers-reduced-motion and evaluates device capability
 * to ensure SWAT RIDE operates smoothly on low-end Android devices.
 */
export function useReducedMotion(): boolean {
  const [prefersReducedMotion, setPrefersReducedMotion] = useState<boolean>(false);

  useEffect(() => {
    if (typeof window === 'undefined') return;

    // Check media query for prefers-reduced-motion
    const mediaQuery = window.matchMedia('(prefers-reduced-motion: reduce)');
    setPrefersReducedMotion(mediaQuery.matches);

    const listener = (event: MediaQueryListEvent) => {
      setPrefersReducedMotion(event.matches);
    };

    mediaQuery.addEventListener('change', listener);
    return () => mediaQuery.removeEventListener('change', listener);
  }, []);

  return prefersReducedMotion;
}

/**
 * Checks if the device is likely a low-end mobile device (e.g. 2GB RAM Android)
 */
export function useIsLowEndDevice(): boolean {
  const [isLowEnd, setIsLowEnd] = useState<boolean>(false);

  useEffect(() => {
    if (typeof window === 'undefined' || typeof navigator === 'undefined') return;

    // Check RAM estimation (navigator.deviceMemory) if supported
    const memory = (navigator as any).deviceMemory;
    const isLowRAM = typeof memory === 'number' && memory <= 4;

    // Check mobile user-agent
    const isMobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(
      navigator.userAgent
    );

    // If mobile or low memory, flag as low-end to serve lightweight animations
    setIsLowEnd(isMobile || isLowRAM);
  }, []);

  return isLowEnd;
}
