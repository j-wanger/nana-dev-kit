import type { EngineEvent } from './types';

/**
 * A tiny async queue bridging a push-based engine event source (a subscribe
 * callback or a streaming loop) into a pull-based async iterable of EngineEvent.
 * Shared by every adapter so the streaming plumbing is written once.
 */
export class EventQueue {
  private items: EngineEvent[] = [];
  private waiters: ((r: IteratorResult<EngineEvent>) => void)[] = [];
  private closed = false;

  push(ev: EngineEvent): void {
    if (this.closed) return;
    const w = this.waiters.shift();
    if (w) w({ value: ev, done: false });
    else this.items.push(ev);
  }

  close(): void {
    this.closed = true;
    let w: ((r: IteratorResult<EngineEvent>) => void) | undefined;
    while ((w = this.waiters.shift())) w({ value: undefined as never, done: true });
  }

  async *stream(): AsyncGenerator<EngineEvent> {
    for (;;) {
      const next = this.items.shift();
      if (next !== undefined) {
        yield next;
        continue;
      }
      if (this.closed) return;
      const res = await new Promise<IteratorResult<EngineEvent>>((r) => this.waiters.push(r));
      if (res.done) return;
      yield res.value;
    }
  }
}
