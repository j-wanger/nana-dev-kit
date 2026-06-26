import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Build/dev config (frontend). Test config lives in vitest.config.ts so the
// test runner doesn't drag the react plugin's vite types into a version clash.
export default defineConfig({
  plugins: [react()],
  clearScreen: false,
  server: { port: 5173, strictPort: true },
});
