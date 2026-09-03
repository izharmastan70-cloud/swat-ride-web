import React from 'react';
import { cn } from '@/lib/utils';

export interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
  helperText?: string;
}

export const Textarea = React.forwardRef<HTMLTextAreaElement, TextareaProps>(
  ({ className, label, error, helperText, id, ...props }, ref) => {
    const textareaId = id || (label ? label.toLowerCase().replace(/\s+/g, '-') : undefined);

    return (
      <div className="w-full">
        {label && (
          <label htmlFor={textareaId} className="block text-xs font-semibold text-mountain-300 uppercase tracking-wider mb-1.5">
            {label}
          </label>
        )}
        <textarea
          id={textareaId}
          ref={ref}
          className={cn(
            'w-full px-4 py-3 bg-mountain-950/80 border border-mountain-800 rounded-xl text-white placeholder-mountain-500 text-sm focus:outline-none focus:ring-2 focus:ring-swat-500 focus:border-swat-500 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed resize-y min-h-[100px]',
            error && 'border-red-500 focus:ring-red-500',
            className
          )}
          {...props}
        />
        {error && <p className="mt-1.5 text-xs text-red-400 font-medium">{error}</p>}
        {!error && helperText && <p className="mt-1.5 text-xs text-mountain-400">{helperText}</p>}
      </div>
    );
  }
);

Textarea.displayName = 'Textarea';
