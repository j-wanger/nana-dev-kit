import {
  useEffect,
  useMemo,
  useRef,
  useState,
  type KeyboardEvent as ReactKeyboardEvent,
  type ReactElement,
} from 'react';
import type { Command } from './commands';

// The Cmd+K command palette (Phase 113, T3 / axis 3 — "every action reachable by
// button, shortcut, or palette search"). A custom, OWNED overlay (no cmdk dep —
// the Ph109 "owned not adopted" ethos; ~6 static commands don't justify a runtime
// dependency in a strict-CSP, sandbox-hardened app). Controlled: the shell (T5)
// owns open/close + the Cmd+K toggle; this only renders the enabled commands,
// filters by query, runs the selected one, and closes.
//
// INERT: command titles are React string children (never innerHTML) — a command
// title can carry a model-influenced file path (e.g. "Revert src/x.ts"), so it
// stays inert like every other model-adjacent string in the surface.

export interface CommandPaletteProps {
  commands: Command[];
  open: boolean;
  onClose: () => void;
}

export function CommandPalette({ commands, open, onClose }: CommandPaletteProps): ReactElement | null {
  const [query, setQuery] = useState('');
  const [selected, setSelected] = useState(0);
  const inputRef = useRef<HTMLInputElement>(null);
  const restoreFocusRef = useRef<HTMLElement | null>(null);

  // Only ENABLED, NON-dangerous commands are reachable here; then narrow by title
  // OR keyword match. Dangerous commands (gate approval) are deliberately excluded
  // so a reflexive Cmd+K then Enter can never run one (the felt-safety footgun).
  const enabled = useMemo(() => commands.filter((c) => c.enabled() && !c.dangerous), [commands]);
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return enabled;
    return enabled.filter(
      (c) =>
        c.title.toLowerCase().includes(q) || c.keywords.some((k) => k.toLowerCase().includes(q)),
    );
  }, [enabled, query]);

  // Fresh query + selection + focus each time it opens; on close, return focus to
  // wherever it was (e.g. the composer) so Cmd+K → Esc leaves you where you were.
  useEffect(() => {
    if (open) {
      restoreFocusRef.current = document.activeElement as HTMLElement | null;
      setQuery('');
      setSelected(0);
      inputRef.current?.focus();
    } else if (restoreFocusRef.current) {
      restoreFocusRef.current.focus?.();
      restoreFocusRef.current = null;
    }
  }, [open]);
  // Keep the cursor in range as the filtered list shrinks.
  useEffect(() => {
    setSelected((s) => (s >= filtered.length ? 0 : s));
  }, [filtered.length]);

  if (!open) return null;

  const onKeyDown = (e: ReactKeyboardEvent<HTMLInputElement>) => {
    switch (e.key) {
      case 'Escape':
        e.preventDefault();
        onClose();
        break;
      case 'ArrowDown':
        e.preventDefault();
        setSelected((s) => Math.min(s + 1, filtered.length - 1));
        break;
      case 'ArrowUp':
        e.preventDefault();
        setSelected((s) => Math.max(s - 1, 0));
        break;
      case 'Enter': {
        e.preventDefault();
        const cmd = filtered[selected];
        if (cmd) {
          cmd.run();
          onClose();
        }
        break;
      }
    }
  };

  return (
    <div className="command-palette" role="dialog" aria-label="Command palette" onClick={onClose}>
      <div className="command-palette__panel" onClick={(e) => e.stopPropagation()}>
        <input
          ref={inputRef}
          className="command-palette__input"
          type="text"
          placeholder="Type a command…"
          aria-label="Search commands"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={onKeyDown}
        />
        <ul className="command-palette__list">
          {filtered.length === 0 ? (
            <li className="command-palette__empty">No matching commands</li>
          ) : (
            filtered.map((c, i) => (
              <li
                key={c.id}
                data-command-id={c.id}
                className={
                  i === selected
                    ? 'command-palette__item command-palette__item--selected'
                    : 'command-palette__item'
                }
                onMouseMove={() => setSelected(i)}
                onClick={() => {
                  c.run();
                  onClose();
                }}
              >
                <span className="command-palette__title">{c.title}</span>
                {c.shortcut ? <span className="command-palette__shortcut">{c.shortcut}</span> : null}
              </li>
            ))
          )}
        </ul>
      </div>
    </div>
  );
}
