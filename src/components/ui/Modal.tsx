'use client';

import React, { useEffect } from 'react';
import { createPortal } from 'react-dom';
import { X } from 'lucide-react';
import { cn } from '@/lib/utils';

export interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  children: React.ReactNode;
  maxWidth?: 'sm' | 'md' | 'lg' | 'xl';
}

export const Modal: React.FC<ModalProps> = ({
  isOpen,
  onClose,
  title,
  children,
  maxWidth = 'md',
}) => {
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    if (isOpen) {
      document.addEventListener('keydown', handleKeyDown);
      document.body.style.overflow = 'hidden';
    }
    return () => {
      document.removeEventListener('keydown', handleKeyDown);
      document.body.style.overflow = 'unset';
    };
  }, [isOpen, onClose]);

  if (!isOpen || typeof document === 'undefined') return null;

  const maxWidthClasses = {
    sm: 'max-w-sm',
    md: 'max-w-md',
    lg: 'max-w-lg',
    xl: 'max-w-xl',
  };

  return createPortal(
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-mountain-950/80 backdrop-blur-md transition-opacity duration-300"
      onClick={onClose}
      role="dialog"
      aria-modal="true"
      aria-labelledby={title ? 'modal-title' : undefined}
    >
      <div
        className={cn(
          'relative w-full bg-mountain-900 border border-mountain-800 rounded-2xl shadow-glass-lg overflow-hidden text-mountain-100 transition-all transform duration-300 scale-100',
          maxWidthClasses[maxWidth]
        )}
        onClick={(e) => e.stopPropagation()}
      >
        {title && (
          <div className="flex items-center justify-between px-6 py-4 border-b border-mountain-800 bg-mountain-950/50">
            <h3 id="modal-title" className="text-lg font-bold text-white">
              {title}
            </h3>
            <button
              onClick={onClose}
              className="p-1 text-mountain-400 hover:text-white rounded-lg transition-colors focus:outline-none focus:ring-2 focus:ring-swat-500"
              aria-label="Close modal"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        )}
        {!title && (
          <button
            onClick={onClose}
            className="absolute top-4 right-4 z-10 p-1.5 text-mountain-400 hover:text-white bg-mountain-950/60 rounded-full transition-colors focus:outline-none focus:ring-2 focus:ring-swat-500"
            aria-label="Close modal"
          >
            <X className="w-5 h-5" />
          </button>
        )}
        <div className="p-6 max-h-[85vh] overflow-y-auto">{children}</div>
      </div>
    </div>,
    document.body
  );
};
