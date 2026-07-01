import { useCallback, useEffect, useState } from 'react';
import type { SessionInfo } from './engine-bridge';
import type { ModelInfo, SkillInfo, TemplateInfo, ThinkingInfo } from '../engine/types';

// Phase 119 T4 — the runtime model picker (and, T5, the thinking toggle) surface.
// A small hook subscribes to the host `session-info` and exposes the current model
// + a cycle action; a shared `Chip` renders both the model picker and the thinking
// toggle (the T4 REFACTOR — one chip component, two consumers). Presentational +
// inert: the chip only calls injected callbacks; every model/thinking change is a
// host inbound the gate-governed session applies (the gate survives the mutation).

/** The minimal bridge surface the model + thinking controls need (injected → testable). */
export interface SessionControlsBridge {
  onSessionInfo(listener: (s: SessionInfo) => void): () => void;
  requestSessionInfo(): Promise<void>;
  requestCycleModel(): Promise<void>;
  requestCycleThinking(): Promise<void>;
}

export function useSessionControls(bridge: SessionControlsBridge): {
  model: ModelInfo | null;
  models: ModelInfo[];
  thinking: ThinkingInfo | null;
  templates: TemplateInfo[];
  skills: SkillInfo[];
  cycleModel: () => void;
  cycleThinking: () => void;
} {
  const [info, setInfo] = useState<SessionInfo | null>(null);
  useEffect(() => {
    const off = bridge.onSessionInfo(setInfo);
    // Populate the chips + palette command sources at mount. The host builds the
    // (local-only, no model call) session lazily to answer this.
    void bridge.requestSessionInfo();
    return off;
  }, [bridge]);
  const cycleModel = useCallback(() => void bridge.requestCycleModel(), [bridge]);
  const cycleThinking = useCallback(() => void bridge.requestCycleThinking(), [bridge]);
  return {
    model: info?.model ?? null,
    models: info?.models ?? [],
    thinking: info?.thinking ?? null,
    templates: info?.templates ?? [],
    skills: info?.skills ?? [],
    cycleModel,
    cycleThinking,
  };
}

/**
 * A reusable status chip: a small `label: value` pill, optionally clickable to
 * cycle. Shared by the model picker (T4) and the thinking toggle (T5). Inert —
 * it never reaches the host except through the injected onClick.
 */
export function Chip({
  label,
  value,
  onClick,
  title,
  testId,
}: {
  label: string;
  value: string;
  onClick?: () => void;
  title?: string;
  testId?: string;
}): JSX.Element {
  if (onClick) {
    return (
      <button className="chip chip--button" type="button" data-testid={testId} title={title} onClick={onClick}>
        <span className="chip__label">{label}</span>
        <span className="chip__value">{value}</span>
      </button>
    );
  }
  return (
    <span className="chip" data-testid={testId} title={title}>
      <span className="chip__label">{label}</span>
      <span className="chip__value">{value}</span>
    </span>
  );
}

/** The model picker chip (T4). Click cycles to the next available model. */
export function ModelChip({ model, onCycle }: { model: ModelInfo | null; onCycle: () => void }): JSX.Element {
  const value = model ? `${model.label}${model.isLocal ? ' · local' : ''}` : '—';
  return <Chip testId="model-chip" label="model" value={value} onClick={onCycle} title="Cycle model" />;
}

/**
 * The thinking-level toggle chip (T5) — the shared `Chip` (the T4 REFACTOR). Click
 * cycles the level. When the active model does not support thinking (the local $0
 * default), the chip is INERT (no onClick) and shows "off" so it reads as available
 * but not applicable, rather than misleading the user into a no-op.
 */
export function ThinkingChip({
  thinking,
  onCycle,
}: {
  thinking: ThinkingInfo | null;
  onCycle: () => void;
}): JSX.Element {
  const supported = thinking?.supported ?? false;
  const value = !thinking ? '—' : supported ? thinking.level : 'off';
  return (
    <Chip
      testId="thinking-chip"
      label="thinking"
      value={value}
      onClick={supported ? onCycle : undefined}
      title={supported ? 'Cycle thinking level' : 'This model does not support thinking levels'}
    />
  );
}
