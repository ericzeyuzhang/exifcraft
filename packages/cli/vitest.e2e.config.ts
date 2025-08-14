import { defineConfig } from 'vitest/config';
import { resolve } from 'path';

export default defineConfig({
  test: {
    name: 'e2e',
    globals: true,
    testTimeout: 120000, 
    hookTimeout: 60000,  
    setupFiles: ['./tests/e2e/setup.ts'],
    include: ['tests/e2e/**/*.test.ts'],
    exclude: ['node_modules', 'dist'],
    minWorkers: 1,
    maxWorkers: 1,
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, './src'),
    },
  },
});
