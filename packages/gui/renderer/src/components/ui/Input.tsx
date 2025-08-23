import React from 'react';

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {}

export const Input = React.forwardRef<HTMLInputElement, InputProps>(({ className = '', ...props }, ref) => {
  return <input ref={ref} className={`border rounded px-2 py-1 ${className}`} {...props} />;
});

Input.displayName = 'Input';


