'use client';

import React from 'react';
import Link from 'next/link';
import { cn } from '@/lib/utils';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'glass' | 'danger' | 'gold';
  size?: 'sm' | 'md' | 'lg';
  href?: string;
  icon?: React.ReactNode;
  iconPosition?: 'left' | 'right';
  isLoading?: boolean;
}

export const Button: React.FC<ButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  href,
  icon,
  iconPosition = 'left',
  isLoading = false,
  className,
  disabled,
  ...props
}) => {
  const baseStyles =
    'inline-flex items-center justify-center font-medium rounded-xl transition-all duration-300 focus:outline-none focus:ring-2 focus:ring-swat-400 focus:ring-offset-2 focus:ring-offset-mountain-900 disabled:opacity-50 disabled:pointer-events-none select-none';

  const sizeStyles = {
    sm: 'text-xs px-3 py-1.5 gap-1.5',
    md: 'text-sm px-5 py-2.5 gap-2',
    lg: 'text-base px-6 py-3.5 gap-2.5 font-semibold',
  };

  const variantStyles = {
    primary:
      'bg-swat-600 hover:bg-swat-500 text-white shadow-lg shadow-swat-600/30 hover:shadow-swat-500/50 hover:-translate-y-0.5 active:translate-y-0',
    secondary:
      'bg-mountain-800 hover:bg-mountain-700 text-mountain-100 border border-mountain-700 hover:border-mountain-600 hover:-translate-y-0.5 active:translate-y-0',
    outline:
      'border-2 border-swat-500/70 hover:border-swat-400 text-swat-400 hover:bg-swat-950/40 hover:-translate-y-0.5 active:translate-y-0',
    glass:
      'bg-white/10 hover:bg-white/15 text-white border border-white/15 backdrop-blur-md shadow-glass-sm hover:shadow-glass-md hover:-translate-y-0.5 active:translate-y-0',
    danger:
      'bg-red-600 hover:bg-red-500 text-white shadow-lg shadow-red-600/30 hover:shadow-red-500/50 hover:-translate-y-0.5 active:translate-y-0',
    gold:
      'bg-gradient-to-r from-amber-500 to-yellow-500 hover:from-amber-400 hover:to-yellow-400 text-mountain-950 font-bold shadow-lg shadow-amber-500/30 hover:shadow-amber-500/50 hover:-translate-y-0.5 active:translate-y-0',
  };

  const combinedClassName = cn(baseStyles, sizeStyles[size], variantStyles[variant], className);

  const content = (
    <>
      {isLoading && (
        <svg
          className="animate-spin -ml-1 mr-2 h-4 w-4 text-current"
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
        >
          <circle
            className="opacity-25"
            cx="12"
            cy="12"
            r="10"
            stroke="currentColor"
            strokeWidth="4"
          />
          <path
            className="opacity-75"
            fill="currentColor"
            d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
          />
        </svg>
      )}
      {!isLoading && icon && iconPosition === 'left' && <span className="shrink-0">{icon}</span>}
      <span>{children}</span>
      {!isLoading && icon && iconPosition === 'right' && <span className="shrink-0">{icon}</span>}
    </>
  );

  if (href) {
    return (
      <Link href={href} className={combinedClassName}>
        {content}
      </Link>
    );
  }

  return (
    <button className={combinedClassName} disabled={disabled || isLoading} {...props}>
      {content}
    </button>
  );
};
