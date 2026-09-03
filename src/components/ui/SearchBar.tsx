'use client';

import React from 'react';
import { Search, X } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface SearchBarProps {
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  className?: string;
  onClear?: () => void;
}

export const SearchBar: React.FC<SearchBarProps> = ({
  value,
  onChange,
  placeholder = 'Search...',
  className,
  onClear,
}) => {
  return (
    <div className={cn('relative flex items-center w-full', className)}>
      <Search className="absolute left-4 w-5 h-5 text-mountain-400 pointer-events-none" />
      <input
        type="text"
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        className="w-full pl-12 pr-10 py-3 bg-mountain-900/90 border border-mountain-800 rounded-xl text-white placeholder-mountain-400 text-sm focus:outline-none focus:ring-2 focus:ring-swat-500 transition-all duration-200"
      />
      {value && (
        <button
          onClick={() => {
            onChange('');
            onClear?.();
          }}
          className="absolute right-3 p-1 text-mountain-400 hover:text-white rounded-lg transition-colors focus:outline-none"
          aria-label="Clear search"
        >
          <X className="w-4 h-4" />
        </button>
      )}
    </div>
  );
};
