---
title: "Provider defaults to a local OpenAI-compatible model; Claude subscription-OAuth ruled out"
aliases: [provider-defaults-to-local-model, local-model-default, subscription-oauth-ruled-out, no-key-no-billing-default]
category: decisions
tags: [gui-harness, provider, local-model, openai-compatible, anthropic-tos, subscription-oauth, billing, phase-108]
parents: [phase-108-gui-harness-v1-thin-slice]
created: 2026-06-26
updated: 2026-06-26
source: debrief
confidence: high
---

## Context

The GUI harness (Phase 108) embeds an engine in-process behind the app-owned `EngineAdapter` and needs a default provider for the daily loop and for the live e2e tests (T3 provider round-trip, T7 second-adapter). The tempting default was to drive Claude through the maintainer's existing Max subscription token (Pi can authenticate via `AuthStorage.set` OAuth + an `sk-ant-oat` Bearer path), getting "free" frontier inference under the plan quota. Before committing, 3-agent primary-source research checked Anthropic's actual terms (code.claude.com / legal-and-compliance).

## Decision

**Default the harness to a LOCAL OpenAI-compatible backend** (`localhost:8080`, Qwen3.6-35B via llama.cpp) — no key, no billing, no ToS exposure. A Console API key remains an OPTIONAL path; **subscription-OAuth is ruled OUT.**

Primary-source findings that killed the subscription route:
- Anthropic **PROHIBITS** Claude subscription-OAuth (`sk-ant-oat`) in third-party harnesses (~2026-02-20 ToS) and **server-side-blocks** non-official clients.
- From ~2026-04-04, third-party subscription usage is **metered to per-token "extra usage" billing**, NOT drawn from Max-plan quota. Only the official Claude Code binary spends plan quota.
- So a custom harness pays per-token EITHER WAY (Console API key OR metered OAuth) — the subscription gives **zero cost benefit** and carries a ban risk + plaintext `auth.json` exposure.

Alternatives weighed: Console API key (billed, ToS-clean) — kept as optional; subscription-token-anyway (DOMINATED — billed AND ban-risk); local model (CHOSEN — free, ToS-clean, drives both adapters via the OpenAI-compatible surface).

## Consequences

- The default test/daily path needs no credential and incurs no spend → the live e2e tests (real `bash rm` denied through both Pi and Vercel adapters) run for free against the local model.
- The Claude-fidelity path (the Claude Agent SDK adapter) is **DEFERRED** until an Anthropic API key exists — it cannot drive the local backend (Anthropic-API-key-only). This is why the spec's named second adapter was substituted (see [[second-adapter-vercel-ai-sdk]]).
- The spend-ceiling control (T8) treats a `$0` local price as never-tripping; it activates only when a billed provider (Console API key) is configured.
- Reinforces the kit posture: retrieval/verification of the ACTUAL terms over a parametric assumption that "subscription = free quota for any client" — which was false as of 2026-04.

## Source

3-agent primary-source research (code.claude.com legal-and-compliance), 2026-06-26. Realizes Phase 108 T3's provider pivot. Related: [[engine-adapter-in-process-gate]], [[second-adapter-vercel-ai-sdk]].
