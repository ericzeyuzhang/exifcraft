import React from 'react';

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'sm' | 'md';
}

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className = '', variant = 'primary', size = 'md', ...props }, ref) => {
    const base = 'inline-flex items-center justify-center rounded transition-colors disabled:opacity-50 disabled:cursor-not-allowed';
    const sizeCls = size === 'sm' ? 'px-2 py-1 text-sm' : 'px-3 py-1.5';
    const variantCls =
      variant === 'primary'
        ? 'bg-indigo-600 text-white hover:bg-indigo-500'
        : variant === 'secondary'
        ? 'bg-gray-200 text-gray-900 hover:bg-gray-300'
        : 'bg-transparent text-gray-900 hover:bg-gray-100';
    return (
      <button ref={ref} className={`${base} ${sizeCls} ${variantCls} ${className}`} {...props} />
    );
  }
);

Button.displayName = 'Button';


