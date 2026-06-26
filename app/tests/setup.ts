// Mark the test environment as a React act() environment so React 18's act(...)
// in the jsdom UI tests does not warn. Harmless for the node-env tests.
(globalThis as { IS_REACT_ACT_ENVIRONMENT?: boolean }).IS_REACT_ACT_ENVIRONMENT = true;
