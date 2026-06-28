// Mark the test environment as a React act() environment so React 18's act(...)
// in the jsdom UI tests does not warn. Harmless for the node-env tests.
(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;

// jsdom has no ResizeObserver; assistant-ui's composer (Radix useOnResizeContent)
// needs it to render. Stub it so full-surface jsdom tests can mount the Thread.
if (typeof (globalThis as { ResizeObserver?: unknown }).ResizeObserver === 'undefined') {
  (globalThis as { ResizeObserver?: unknown }).ResizeObserver = class {
    observe() {}
    unobserve() {}
    disconnect() {}
  };
}
