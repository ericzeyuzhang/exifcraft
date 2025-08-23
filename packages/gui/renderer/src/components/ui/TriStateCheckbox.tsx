import React from "react"

interface TriStateCheckboxProps {
  checked: boolean | null; // true = checked, false = unchecked, null = indeterminate
  onChange: (checked: boolean | null) => void;
  label?: string;
  className?: string;
  disabled?: boolean;
}

export const TriStateCheckbox: React.FC<TriStateCheckboxProps> = ({
  checked,
  onChange,
  label,
  className = '',
  disabled = false
}) => {
  const handleClick = () => {
    if (disabled) return;
    onChange(checked);
  };

  const getCheckboxState = (): boolean | "mixed" => {
    if (checked === true) return true;
    if (checked === false) return false;
    return "mixed"; // indeterminate state
  };

  const getIcon = () => {
    if (checked === true) {
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
          <polyline points="20 6 9 17 4 12" />
        </svg>
      );
    }
    if (checked === null) {
      return (
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round">
          <line x1="5" y1="12" x2="19" y2="12" />
        </svg>
      );
    }
    return null;
  };

  return (
    <div className={`flex items-center space-x-2 ${className}`}>
      <button
        type="button"
        role="checkbox"
        aria-checked={getCheckboxState()}
        disabled={disabled}
        onClick={handleClick}
        className={`peer h-4 w-4 shrink-0 rounded-sm border border-gray-300 bg-white ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 ${checked === true ? "bg-indigo-600 border-indigo-600 text-white" : ""} ${checked === null ? "bg-indigo-100 border-indigo-300 text-indigo-600" : ""}`}
        title={
          checked === true ? 'All selected - click to deselect all' :
          checked === false ? 'None selected - click to select all' :
          'Partially selected - click to select all'
        }
      >
        <div className="flex items-center justify-center text-current">
          {getIcon()}
        </div>
      </button>
      {label && (
        <label 
          onClick={handleClick}
          className={`text-sm font-medium leading-none cursor-pointer ${disabled ? "cursor-not-allowed opacity-50" : ""}`}
        >
          {label}
        </label>
      )}
    </div>
  );
};

// No separate Checkbox export to avoid unused component overhead
