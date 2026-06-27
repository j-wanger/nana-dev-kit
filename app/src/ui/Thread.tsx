import {
  AssistantRuntimeProvider,
  ThreadPrimitive,
  MessagePrimitive,
  ComposerPrimitive,
  type AssistantRuntime,
} from '@assistant-ui/react';
import { ToolCallView } from './tool-call-view';

/**
 * The chat surface (Phase 109, T1 / axis 4 — visible streaming). Composes
 * assistant-ui's unstyled primitives over the engine-bound runtime
 * (useChatRuntime). All model/tool text is a React string child (inert); the
 * felt-quality styling lives in src/styles.css (the maintainer's call).
 */
export function Thread({ runtime }: { runtime: AssistantRuntime }) {
  return (
    <AssistantRuntimeProvider runtime={runtime}>
      <ThreadPrimitive.Root className="thread">
        <ThreadPrimitive.Viewport className="thread__viewport">
          <ThreadPrimitive.Empty>
            <p className="thread__empty">Message the harness to begin.</p>
          </ThreadPrimitive.Empty>
          <ThreadPrimitive.Messages components={{ Message: MessageView }} />
          <ThreadPrimitive.If running>
            <div className="thread__working" aria-live="polite">
              <span className="thread__working-dot" aria-hidden="true" />
              working… (local models are slow — this can take a few minutes)
            </div>
          </ThreadPrimitive.If>
        </ThreadPrimitive.Viewport>
        <ComposerPrimitive.Root className="composer">
          <ComposerPrimitive.Input className="composer__input" placeholder="Message the harness…" />
          {/* While a turn runs the agent is busy: swap Send for a Stop that
              interrupts the in-flight turn (composer cancel -> bridge -> host abort). */}
          <ThreadPrimitive.If running={false}>
            <ComposerPrimitive.Send className="composer__send">Send</ComposerPrimitive.Send>
          </ThreadPrimitive.If>
          <ThreadPrimitive.If running>
            <ComposerPrimitive.Cancel className="composer__cancel">Stop</ComposerPrimitive.Cancel>
          </ThreadPrimitive.If>
        </ComposerPrimitive.Root>
      </ThreadPrimitive.Root>
    </AssistantRuntimeProvider>
  );
}

function MessageView() {
  return (
    <MessagePrimitive.Root className="message">
      <MessagePrimitive.Parts
        components={{
          Text: ({ text }) => <span className="message__text">{text}</span>,
          tools: {
            Override: (props) => (
              <ToolCallView
                toolName={props.toolName}
                argsText={props.argsText}
                result={props.result}
                isError={props.isError}
                status={props.status}
              />
            ),
          },
        }}
      />
    </MessagePrimitive.Root>
  );
}
