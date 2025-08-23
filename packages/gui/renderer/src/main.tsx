import React from 'react';
import { createRoot } from 'react-dom/client';
import { App } from './ui/App';

declare global {
  interface Window {
    exifcraft?: any;
  }
}

const root = createRoot(document.getElementById('root')!);
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>
);


