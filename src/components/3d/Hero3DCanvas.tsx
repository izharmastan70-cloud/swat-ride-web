'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import {
  ChevronLeft,
  ChevronRight,
  Pause,
  Play,
  Sparkles,
  Layers,
  ShieldCheck,
  ArrowUpRight,
} from 'lucide-react';
import { cn } from '@/lib/utils';

export interface EcosystemSlide {
  id: string;
  titleEn: string;
  titleUr: string;
  tag: string;
  category: string;
  image: string;
  color: string;
}

export const SWAT_ECOSYSTEM_SLIDES: EcosystemSlide[] = [
  {
    id: 'corolla-fielder',
    titleEn: 'Normal Ride Car — Fielder Hybrid & Corolla G',
    titleUr: 'نارمل رائیڈ کار — فیلڈر ہائبرڈ اور کرولا جی',
    tag: 'DAILY TAXI',
    category: 'Ride Car',
    image: '/images/swat-corolla-fielder.jpg',
    color: '#10B981', // Emerald
  },
  {
    id: 'ride-bike',
    titleEn: 'Normal Ride Bike — Passenger Moto Taxi',
    titleUr: 'رائیڈ بائیک سروس — فوری اور سستی بائیک رائیڈ',
    tag: 'RIDE BIKE',
    category: 'Ride Bike',
    image: '/images/swat-ride-bike.jpg',
    color: '#34D399', // Bright Teal
  },
  {
    id: 'rickshaw-city',
    titleEn: 'Auto Rickshaw (Raksha) — Mingora City Transit',
    titleUr: 'سوات رکشہ / چنگچی سروس — مینگورہ بازار',
    tag: 'RICKSHAW',
    category: 'Rickshaw',
    image: '/images/swat-rickshaw.jpg',
    color: '#059669', // Forest
  },
  {
    id: '4x4-new-prado',
    titleEn: '4x4 Tourism Fleet — Latest New-Model Prado',
    titleUr: '4x4 نیو ماڈل پراڈو — کالام اور مہوڈنڈ جھیل ٹورز',
    tag: '4X4 NEW PRADO',
    category: '4x4 Prado',
    image: '/images/swat-4x4-jeep.jpg', // Wide-angle zoomed out mountain 4x4 SUV
    color: '#10B981', // Emerald
  },
  {
    id: 'swat-tour-scene',
    titleEn: 'Swat Tours & Sightseeing — Mahodand Lake',
    titleUr: 'سوات ٹورز اور سیاحت — مہوڈنڈ جھیل اور کالام',
    tag: 'SWAT TOURS',
    category: 'Swat Tour',
    image: '/images/swat-tour-scene.jpg',
    color: '#0D9488', // Teal
  },
  {
    id: 'food-delivery-bike',
    titleEn: 'Food Delivery Bike & Thermal Bag Rider',
    titleUr: 'فوڈ ڈیلیوری بائیک رائیڈر — گرم اور تازہ کھانا',
    tag: 'FOOD BIKE',
    category: 'Food Delivery',
    image: '/images/swat-food-bike.jpg',
    color: '#F59E0B', // Amber Gold
  },
  {
    id: 'school-van-bus',
    titleEn: 'School Bus, Suzuki Van & Student Transport',
    titleUr: 'اسکول بس، سوزوکی وین اور اسٹوڈنٹ ٹرانسپورٹ',
    tag: 'SCHOOL BUS/VAN',
    category: 'School Van',
    image: '/images/swat-student-van.jpg',
    color: '#38BDF8', // Sky Blue
  },
  {
    id: 'cargo-loader-truck',
    titleEn: 'Cargo Pickup & Suzuki Loader Truck',
    titleUr: 'کارگو ٹرک اور لوڈر سروس — سامان کی ترسیل',
    tag: 'CARGO LOADER',
    category: 'Cargo Truck',
    image: '/images/swat-cargo-truck.jpg',
    color: '#D97706', // Warm Amber
  },
  {
    id: 'swat-hotels-resorts',
    titleEn: 'Swat Hotels & Stays — Malam Jabba & Kalam',
    titleUr: 'سوات ہوٹلز اور ریزورٹس — مالم جبہ اور کالام',
    tag: 'HOTELS',
    category: 'Swat Hotels',
    image: '/images/swat-hotel-view.jpg',
    color: '#047857', // Deep Alpine
  },
  {
    id: 'swat-drone-panorama',
    titleEn: 'Swat Valley — Mingora, Charbagh & Kalam Aerial View',
    titleUr: 'وادی سوات — مینگورہ، چارباغ اور کالام کا ایریل ویو',
    tag: 'DRONE SHOT',
    category: 'Drone View',
    image: '/images/swat-drone-view.jpg',
    color: '#0E7490', // Cyan
  },
];

export const Hero3DCanvas: React.FC = () => {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [prevIndex, setPrevIndex] = useState(0);
  const [direction, setDirection] = useState<'next' | 'prev'>('next');
  const [isPaused, setIsPaused] = useState(false);
  const [progress, setProgress] = useState(0);
  const [is3DMode, setIs3DMode] = useState(false);

  // Mouse Parallax Tilt state
  const containerRef = useRef<HTMLDivElement>(null);
  const [rotateX, setRotateX] = useState(0);
  const [rotateY, setRotateY] = useState(0);
  const [isHovered, setIsHovered] = useState(false);

  const totalSlides = SWAT_ECOSYSTEM_SLIDES.length;
  const currentSlide = SWAT_ECOSYSTEM_SLIDES[currentIndex];

  const handleNext = () => {
    setDirection('next');
    setPrevIndex(currentIndex);
    setCurrentIndex((prev) => (prev + 1) % totalSlides);
    setProgress(0);
  };

  const handlePrev = () => {
    setDirection('prev');
    setPrevIndex(currentIndex);
    setCurrentIndex((prev) => (prev - 1 + totalSlides) % totalSlides);
    setProgress(0);
  };

  const handleSelect = (idx: number) => {
    if (idx === currentIndex) return;
    setDirection(idx > currentIndex ? 'next' : 'prev');
    setPrevIndex(currentIndex);
    setCurrentIndex(idx);
    setProgress(0);
  };

  // 3-second auto-slide interval (3000ms total)
  useEffect(() => {
    if (isPaused) return;

    const interval = setInterval(() => {
      setProgress((oldProgress) => {
        if (oldProgress >= 100) {
          setDirection('next');
          setPrevIndex(currentIndex);
          setCurrentIndex((prev) => (prev + 1) % totalSlides);
          return 0;
        }
        return oldProgress + 50 / 30; // ~100% in 3000ms
      });
    }, 50);

    return () => clearInterval(interval);
  }, [isPaused, totalSlides, currentIndex]);

  // 3D Mouse Parallax Tilt calculation
  const handleMouseMove = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!containerRef.current || is3DMode) return;
    const rect = containerRef.current.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;

    // Max tilt 6 degrees for smooth depth
    const rX = ((y - centerY) / centerY) * -6;
    const rY = ((x - centerX) / centerX) * 6;

    setRotateX(rX);
    setRotateY(rY);
  };

  const handleMouseEnter = () => {
    setIsHovered(true);
    setIsPaused(true);
  };

  const handleMouseLeave = () => {
    setIsHovered(false);
    setIsPaused(false);
    setRotateX(0);
    setRotateY(0);
  };

  return (
    <div
      ref={containerRef}
      onMouseMove={handleMouseMove}
      onMouseEnter={handleMouseEnter}
      onMouseLeave={handleMouseLeave}
      style={{
        perspective: '1400px',
      }}
      className="relative w-full h-full min-h-[440px] sm:min-h-[500px] lg:min-h-[540px] select-none group"
    >
      <div
        style={{
          transform: is3DMode
            ? 'rotateX(8deg) rotateY(-10deg) scale(0.96) translateZ(20px)'
            : isHovered
            ? `rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateZ(10px)`
            : 'rotateX(0deg) rotateY(0deg) translateZ(0px)',
          transition: isHovered && !is3DMode ? 'none' : 'all 0.7s cubic-bezier(0.2, 0.8, 0.2, 1)',
        }}
        className={cn(
          'relative w-full h-full rounded-3xl overflow-hidden border border-white/20 shadow-glass-lg bg-mountain-950 flex flex-col justify-between',
          is3DMode && 'shadow-glow-emerald border-swat-400/60'
        )}
      >
        {/* ======================================================================
            1. 3D SCROLL / PARALLAX SLIDE TRANSITION BACKGROUND IMAGES
               ("jo image slide jate hain to ye thora sa scroll type ho")
           ====================================================================== */}
        <div
          style={{ perspective: '1200px' }}
          className="absolute inset-0 w-full h-full overflow-hidden"
        >
          {SWAT_ECOSYSTEM_SLIDES.map((slide, idx) => {
            const isActive = idx === currentIndex;
            const isPrevious = idx === prevIndex && idx !== currentIndex;

            // 3D Scroll Transform calculations
            let transformStyle = 'translate3d(0, 0, 0) rotateY(0deg) scale(1)';
            let opacityStyle = 0;
            let zIndexStyle = 0;

            if (isActive) {
              opacityStyle = 1;
              zIndexStyle = 10;
              transformStyle = 'translate3d(0, 0, 0) rotateY(0deg) scale(1)';
            } else if (isPrevious) {
              opacityStyle = 0;
              zIndexStyle = 5;
              transformStyle =
                direction === 'next'
                  ? 'translate3d(-40%, 0, -120px) rotateY(18deg) scale(0.95)'
                  : 'translate3d(40%, 0, -120px) rotateY(-18deg) scale(0.95)';
            } else {
              opacityStyle = 0;
              zIndexStyle = 0;
              transformStyle = 'translate3d(60%, 0, -180px) rotateY(-22deg) scale(0.9)';
            }

            return (
              <div
                key={slide.id}
                style={{
                  transform: transformStyle,
                  opacity: opacityStyle,
                  zIndex: zIndexStyle,
                  transition: 'all 0.85s cubic-bezier(0.25, 0.8, 0.25, 1)',
                }}
                className="absolute inset-0 w-full h-full transform-gpu"
              >
                <img
                  src={slide.image}
                  alt={slide.titleEn}
                  className="w-full h-full object-cover"
                />
                {/* Minimal subtle gradient ONLY along edges for text contrast */}
                <div className="absolute inset-0 bg-gradient-to-t from-mountain-950/70 via-transparent to-mountain-950/20 pointer-events-none" />
              </div>
            );
          })}
        </div>

        {/* ======================================================================
            2. TOP BAR: Tiny Official Logo Pill (Left) + 3D View Mode Button + Status Pill (Right)
           ====================================================================== */}
        <div className="relative z-20 flex items-center justify-between p-3 sm:p-4">
          {/* Top-Left: Tiny Official Logo Pill */}
          <div className="flex items-center gap-2 px-2.5 py-1 rounded-xl bg-mountain-950/80 border border-white/20 backdrop-blur-md shadow-sm">
            <img
              src="/logo.jpg"
              alt="SWAT RIDE"
              className="w-5 h-5 rounded-md object-cover"
            />
            <span className="text-[11px] font-black tracking-wide text-white">
              SWAT RIDE
            </span>
          </div>

          {/* Top-Right: 3D View Mode Toggle + Interactive Badge */}
          <div className="flex items-center gap-2">
            <button
              onClick={() => setIs3DMode(!is3DMode)}
              className={cn(
                'flex items-center gap-1 px-2.5 py-1 rounded-xl text-[11px] font-bold border transition-all shadow-sm',
                is3DMode
                  ? 'bg-swat-600 text-white border-swat-400 scale-105'
                  : 'bg-mountain-950/80 text-mountain-300 border-white/20 hover:text-white'
              )}
              title="Toggle 3D Perspective Mode"
            >
              <Layers className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">{is3DMode ? '3D Active' : '3D View'}</span>
            </button>

            <div className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-mountain-950/80 border border-swat-500/30 text-[11px] font-semibold text-swat-300 backdrop-blur-md shadow-sm">
              <Sparkles className="w-3 h-3 text-swat-400 animate-pulse" />
              <span>Interactive 3D Swat Ecosystem (Drag to inspect)</span>
            </div>
          </div>
        </div>

        {/* ======================================================================
            3. TINY LOGO-SIZED CORNER TEXT PILL ("opar text ek kony me ho aur chota ho")
               Compact corner badge sitting in the bottom-left corner!
           ====================================================================== */}
        <div className="relative z-20 px-3 sm:px-4 pb-2 mt-auto">
          <div className="inline-flex items-center gap-2.5 px-3 py-1.5 rounded-xl bg-mountain-950/85 border border-white/20 backdrop-blur-xl shadow-md max-w-[260px] sm:max-w-[300px]">
            {/* Small Colored Circle Tag */}
            <span
              className="w-2.5 h-2.5 rounded-full shrink-0 shadow-sm"
              style={{ backgroundColor: currentSlide.color }}
            />
            <div className="min-w-0">
              {/* Compact English Title */}
              <h3 className="text-xs sm:text-sm font-extrabold text-white truncate">
                {currentSlide.titleEn}
              </h3>
              {/* Compact Urdu Title */}
              <p className="text-[10px] sm:text-[11px] font-nastaliq text-swat-300 truncate -mt-0.5">
                {currentSlide.titleUr}
              </p>
            </div>
            <span className="text-[10px] font-mono font-bold text-mountain-400 shrink-0 ml-1">
              {currentIndex + 1}/{totalSlides}
            </span>
          </div>
        </div>

        {/* ======================================================================
            4. TINY BOTTOM CONTROLS & 3-SECOND PROGRESS BAR
           ====================================================================== */}
        <div className="relative z-20 border-t border-white/10 bg-mountain-950/80 backdrop-blur-md px-3 py-1.5">
          {/* Animated 3-Second Progress Bar */}
          <div className="w-full h-0.5 bg-mountain-800 rounded-full overflow-hidden mb-1.5">
            <div
              className="h-full bg-gradient-to-r from-swat-400 to-amber-400 transition-all duration-75 ease-linear"
              style={{ width: `${progress}%` }}
            />
          </div>

          {/* Small Navigation Controls */}
          <div className="flex items-center justify-between text-[10px] gap-2">
            {/* Compact Slide Category Buttons (Horizontally scrollable) */}
            <div className="flex items-center gap-1 overflow-x-auto py-0.5 max-w-[72%] sm:max-w-[80%] no-scrollbar">
              {SWAT_ECOSYSTEM_SLIDES.map((slide, idx) => {
                const isSelected = idx === currentIndex;
                return (
                  <button
                    key={slide.id}
                    onClick={() => handleSelect(idx)}
                    className={cn(
                      'px-2 py-0.5 rounded-md font-semibold transition-all shrink-0 text-[10px] border',
                      isSelected
                        ? 'bg-swat-600 text-white border-swat-400 font-bold scale-105'
                        : 'bg-mountain-900/60 text-mountain-400 border-mountain-800/80 hover:text-white'
                    )}
                  >
                    {idx + 1}. {slide.category}
                  </button>
                );
              })}
            </div>

            {/* Prev / Play-Pause / Next Buttons */}
            <div className="flex items-center gap-1 shrink-0">
              <button
                onClick={handlePrev}
                className="p-1 rounded-lg bg-mountain-900 hover:bg-mountain-800 text-mountain-200 hover:text-white border border-mountain-700"
                aria-label="Previous slide"
              >
                <ChevronLeft className="w-3.5 h-3.5" />
              </button>

              <button
                onClick={() => setIsPaused(!isPaused)}
                className="p-1 rounded-lg bg-mountain-900 hover:bg-mountain-800 text-mountain-200 hover:text-white border border-mountain-700"
                aria-label={isPaused ? 'Resume auto-slide' : 'Pause auto-slide'}
              >
                {isPaused ? <Play className="w-3.5 h-3.5 text-swat-400" /> : <Pause className="w-3.5 h-3.5" />}
              </button>

              <button
                onClick={handleNext}
                className="p-1 rounded-lg bg-mountain-900 hover:bg-mountain-800 text-mountain-200 hover:text-white border border-mountain-700"
                aria-label="Next slide"
              >
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
