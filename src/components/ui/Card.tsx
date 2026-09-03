'use client';

import React from 'react';
import { cn } from '@/lib/utils';

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: 'default' | 'glass' | 'elevated' | 'interactive';
  children: React.ReactNode;
}

export const Card: React.FC<CardProps> = ({
  children,
  variant = 'default',
  className,
  ...props
}) => {
  const baseStyles = 'rounded-2xl transition-all duration-300 border overflow-hidden';

  const variantStyles = {
    default: 'bg-mountain-900/80 border-mountain-800 text-mountain-100 shadow-lg',
    glass: 'bg-white/5 backdrop-blur-xl border-white/10 text-white shadow-glass-md',
    elevated: 'bg-gradient-to-b from-mountain-800/90 to-mountain-900/90 border-mountain-700/60 text-white shadow-xl',
    interactive:
      'bg-mountain-900/90 border-mountain-800/80 hover:border-swat-500/50 hover:shadow-glow-emerald hover:-translate-y-1 text-mountain-100 cursor-pointer',
  };

  return (
    <div className={cn(baseStyles, variantStyles[variant], className)} {...props}>
      {children}
    </div>
  );
};
