// Hard interrupt (Phase 108, T8). A GUI interrupt cancels an in-flight or HUNG
// tool call promptly (≤2s requirement) by racing the operation against the
// abort signal — so cancellation does not depend on the operation itself
// cooperating or ever resolving.

export type InterruptResult<T> =
  | { completed: true; value: T }
  | { completed: false; interrupted: boolean; error?: string };

export async function runInterruptible<T>(
  fn: (signal: AbortSignal) => Promise<T>,
  signal: AbortSignal,
): Promise<InterruptResult<T>> {
  if (signal.aborted) return { completed: false, interrupted: true };

  return new Promise<InterruptResult<T>>((resolve) => {
    const onAbort = () => resolve({ completed: false, interrupted: true });
    signal.addEventListener('abort', onAbort, { once: true });

    fn(signal).then(
      (value) => {
        signal.removeEventListener('abort', onAbort);
        resolve({ completed: true, value });
      },
      (err: unknown) => {
        signal.removeEventListener('abort', onAbort);
        resolve({
          completed: false,
          interrupted: signal.aborted,
          error: err instanceof Error ? err.message : String(err),
        });
      },
    );
  });
}
