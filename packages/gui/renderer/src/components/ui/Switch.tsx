import React from 'react';

export interface SwitchProps extends React.InputHTMLAttributes<HTMLInputElement> {}

export const Switch: React.FC<SwitchProps> = ({ className = '', ...props }) => {
  return (
    <label className={`inline-flex items-center gap-2 cursor-pointer ${className}`}>
      <input type="checkbox" className="sr-only peer" {...props} />
      <div className="w-10 h-5 rounded-full bg-gray-300 peer-checked:bg-indigo-600 relative transition-colors">
        <div className="absolute top-0.5 left-0.5 w-4 h-4 rounded-full bg-white peer-checked:translate-x-5 transition-transform" />
      </div>
    </label>
  );
};


