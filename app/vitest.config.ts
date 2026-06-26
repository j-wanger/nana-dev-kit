import { defineConfig } from 'vitest/config';

// The engine adapters and gate are Node-side code, so tests run in the node env.
// No plugins here: the adapter/gate tests are plain .ts and need no JSX transform.
export default defineConfig({
  test: {
    environment: 'node',
    include: ['tests/**/*.test.ts', 'tests/**/*.test.tsx'],
    setupFiles: ['./tests/setup.ts'],
  },
});
