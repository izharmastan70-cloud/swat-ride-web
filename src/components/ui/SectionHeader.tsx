import React from 'react';
import { cn } from '@/lib/utils';

export interface SectionHeaderProps {
  badge?: string;
  title: string;
  subtitle?: string;
  align?: 'left' | 'center';
  className?: string;
}

export const SectionHeader: React.FC<SectionHeaderProps> = ({
  badge,
  title,
  subtitle,
  align = 'center',
  className,
}) => {
  return (
    <div
      className={cn(
        'max-w-3xl mb-12',
        align === 'center' ? 'mx-auto text-center' : 'text-left',
        className
      )}
    >
      {badge && (
        <span className="inline-block px-3 py-1 mb-3 text-xs font-bold tracking-widest text-swat-300 uppercase bg-swat-950/80 border border-swat-500/30 rounded-full shadow-sm">
          {badge}
        </span>
      )}
      <h2 className="text-3xl sm:text-4xl lg:text-5xl font-extrabold text-white tracking-tight leading-tight">
        {title}
      </h2>
      {subtitle && (
        <p className="mt-4 text-base sm:text-lg text-mountain-300 leading-relaxed font-normal">
          {subtitle}
        </p>
      )}
    </div>
  );
};
