import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default defineConfig({
  root: 'renderer',
  plugins: [react()],
  resolve: {
    alias: {
      'exifcraft-core/schema': path.resolve(__dirname, '../core/src/schema.ts')
    }
  },
  server: {
    port: 5173,
    strictPort: true
  },
  build: {
    outDir: '../dist-renderer'
  }
});


