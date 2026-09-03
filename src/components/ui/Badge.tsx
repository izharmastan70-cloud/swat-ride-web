import React from 'react';
import { cn } from '@/lib/utils';

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: 'emerald' | 'amber' | 'sky' | 'coral' | 'glass' | 'neutral';
  children: React.ReactNode;
}

export const Badge: React.FC<BadgeProps> = ({
  children,
  variant = 'emerald',
  className,
  ...props
}) => {
  const baseStyles = 'inline-flex items-center px-2.5 py-1 rounded-full text-xs font-semibold tracking-wide uppercase transition-colors';

  const variantStyles = {
    emerald: 'bg-swat-950/80 text-swat-300 border border-swat-500/30',
    amber: 'bg-amber-950/80 text-amber-300 border border-amber-500/30',
    sky: 'bg-sky-950/80 text-sky-300 border border-sky-500/30',
    coral: 'bg-rose-950/80 text-rose-300 border border-rose-500/30',
    glass: 'bg-white/10 text-white border border-white/20 backdrop-blur-md',
    neutral: 'bg-mountain-800 text-mountain-300 border border-mountain-700',
  };

  return (
    <span className={cn(baseStyles, variantStyles[variant], className)} {...props}>
      {children}
    </span>
  );
};
