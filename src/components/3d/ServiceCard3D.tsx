'use client';

import React, { useState, useRef } from 'react';
import Link from 'next/link';
import * as Icons from 'lucide-react';
import { ServiceItem, Locale } from '@/types';
import { translateText } from '@/i18n/dictionaries';
import { cn } from '@/lib/utils';
import { useReducedMotion } from './ReducedMotionHook';

export interface ServiceCard3DProps {
  service: ServiceItem;
  locale?: Locale;
  className?: string;
}

export const ServiceCard3D: React.FC<ServiceCard3DProps> = ({
  service,
  locale = 'en',
  className,
}) => {
  const cardRef = useRef<HTMLDivElement>(null);
  const [rotateX, setRotateX] = useState(0);
  const [rotateY, setRotateY] = useState(0);
  const [isHovered, setIsHovered] = useState(false);
  const reducedMotion = useReducedMotion();

  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (reducedMotion || !cardRef.current) return;
    const rect = cardRef.current.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;

    const rX = ((y - centerY) / centerY) * -8; // max tilt 8 degrees
    const rY = ((x - centerX) / centerX) * 8;

    setRotateX(rX);
    setRotateY(rY);
  };

  const handleMouseEnter = () => {
    if (!reducedMotion) setIsHovered(true);
  };

  const handleMouseLeave = () => {
    setIsHovered(false);
    setRotateX(0);
    setRotateY(0);
  };

  const titleText = translateText(service.title, locale);
  const descText = translateText(service.shortDescription, locale);
  const badgeText = service.badge ? translateText(service.badge, locale) : null;
  const ctaText = translateText(service.ctaText, locale);

  // Map service slug to vehicle/service image
  const SERVICE_IMAGES: Record<string, string> = {
    ride: '/images/swat-ride-vehicle.jpg',
    food: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?auto=format&fit=crop&w=600&q=80',
    cargo: '/images/swat-cargo-truck.jpg',
    'student-ride': '/images/swat-student-van.jpg',
    hotels: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=600&q=80',
    tours: '/images/swat-4x4-jeep.jpg',
  };
  const serviceImage = SERVICE_IMAGES[service.slug] || '/images/swat-ride-vehicle.jpg';

  // Dynamically resolve icon from Lucide
  const IconComponent = (Icons as any)[service.iconName] || Icons.Car;

  return (
    <div
      ref={cardRef}
      onMouseMove={handleMouseMove}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      style={{
        perspective: '1000px',
      }}
      className={cn('group relative block w-full h-full', className)}
    >
      <div
        style={{
          transform: isHovered
            ? `rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateZ(12px)`
            : 'rotateX(0deg) rotateY(0deg) translateZ(0px)',
          transition: isHovered ? 'none' : 'all 0.5s cubic-bezier(0.2, 0.8, 0.2, 1)',
        }}
        className="relative flex flex-col justify-between h-full rounded-2xl bg-gradient-to-br from-mountain-900/90 to-mountain-950/90 border border-mountain-800/80 hover:border-swat-500/50 shadow-glass-md hover:shadow-glow-emerald transition-all duration-500 overflow-hidden"
      >
        {/* Top Vehicle / Service Image Banner */}
        <div className="relative h-44 bg-mountain-800 overflow-hidden">
          <img
            src={serviceImage}
            alt={titleText}
            className="w-full h-full object-cover transition-transform duration-500 group-hover:scale-105"
          />
          <div className="absolute inset-0 bg-gradient-to-t from-mountain-900 via-mountain-900/40 to-transparent" />

          {/* Top Bar: Icon & Optional Badge */}
          <div className="absolute top-4 left-4 right-4 flex items-center justify-between z-10">
            <div
              className="flex items-center justify-center w-10 h-10 rounded-xl bg-mountain-950/90 border border-white/20 shadow-sm transition-transform duration-300 group-hover:scale-110"
              style={{ color: service.themeColor }}
            >
              <IconComponent className="w-5 h-5" />
            </div>
            {badgeText && (
              <span
                className="px-2.5 py-1 text-xs font-semibold rounded-full uppercase tracking-wider border backdrop-blur-md"
                style={{
                  backgroundColor: `${service.themeColor}30`,
                  borderColor: `${service.themeColor}60`,
                  color: service.themeColor,
                }}
              >
                {badgeText}
              </span>
            )}
          </div>
        </div>

        <div className="p-6 sm:p-8 flex-1 flex flex-col justify-between">
          <div>
            {/* Title & Description */}
            <h3 className="text-xl sm:text-2xl font-bold text-white tracking-tight mb-3 group-hover:text-swat-300 transition-colors">
              {titleText}
            </h3>
            <p className="text-sm sm:text-base text-mountain-300 leading-relaxed mb-6">
              {descText}
            </p>
          </div>

          {/* Bottom CTA Links */}
          <div className="flex items-center justify-between pt-4 border-t border-mountain-800/80 mt-auto">
            <Link
              href={`/${service.slug}`}
              className="inline-flex items-center text-sm font-semibold text-swat-400 hover:text-swat-300 transition-colors group/link"
            >
              <span>Explore {titleText}</span>
              <Icons.ArrowRight className="w-4 h-4 ml-1.5 transition-transform duration-200 group-hover/link:translate-x-1" />
            </Link>
            <Link
              href={service.ctaLink}
              className="text-xs font-medium px-3 py-1.5 rounded-lg bg-swat-600/20 hover:bg-swat-600/40 text-swat-300 border border-swat-500/30 transition-colors"
            >
              {ctaText}
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};
