#!/usr/bin/env bash
# Cognitive readiness diagnostic — structured report of harness activation state.
# Sourced by session-start.sh. Consolidates enforcement, wiki, heuristic, and memory status.

# Kit inventory line (shared by the normal and uninitialized paths).
_nana_kit_summary() {
  local skill_count=0 hook_count=0 kit_ver="" kp
  [ -d "$HOME/.claude/skills" ] && skill_count=$(find "$HOME/.claude/skills" -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
  [ -d "$HOME/.claude/hooks" ] && hook_count=$(find "$HOME/.claude/hooks" -maxdepth 1 -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
  if [ -f "$HOME/.claude/.nana-dev-kit-path" ]; then
    kp=$(cat "$HOME/.claude/.nana-dev-kit-path" 2>/dev/null || true)
    [ -n "$kp" ] && [ -f "$kp/VERSION" ] && kit_ver=" v$(cat "$kp/VERSION")"
  fi
  echo "  kit: ${skill_count} skills, ${hook_count} hooks${kit_ver}"
}

check_cognitive_readiness() {
  # Uninitialized project (no .dev-wiki/): the root action is /nana-init, not a
  # wall of inactive sub-statuses. Emit one actionable nudge and skip the
  # per-component probes (including the memory import check) — they are all moot
  # before the project is bootstrapped.
  if [ ! -d ".dev-wiki" ]; then
    echo "[nana:cognitive] Project not initialized — no .dev-wiki/ found."
    echo "  Run /nana-init to bootstrap dev-wiki lifecycle, harness rules, and (optional) knowledge wiki."
    _nana_kit_summary
    return 0
  fi

  local enforce_status="inactive"
  local wiki_status="none"
  local heuristic_count=0
  local domain_article_count=0
  local mem_status="not configured"
  local needs_attention=""

  # Enforcement
  if [ -f "$HOME/.claude/enforce" ]; then
    enforce_status="active"
  else
    needs_attention="${needs_attention}enforce "
  fi

  # Wiki articles (not just existence — count actual content)
  if [ -d "wiki" ]; then
    local article_count
    article_count=$(find wiki -name "*.md" -not -name "schema.md" -not -name "index.md" -not -name "SCHEMA.md" -not -path "*/inbox/*" -not -path "*/.processed/*" 2>/dev/null | wc -l | tr -d ' ')
    domain_article_count=$(find wiki -name "*.md" -not -name "schema.md" -not -name "index.md" -not -name "SCHEMA.md" -not -path "*/heuristics/*" -not -path "*/inbox/*" -not -path "*/.processed/*" 2>/dev/null | wc -l | tr -d ' ')
    if [ "$article_count" -gt 0 ] 2>/dev/null; then
      wiki_status="$article_count articles ($domain_article_count domain)"
      if [ "$domain_article_count" -eq 0 ] 2>/dev/null; then
        needs_attention="${needs_attention}wiki-domain "
      fi
    else
      wiki_status="empty"
      needs_attention="${needs_attention}wiki-empty "
    fi
  fi

  # Heuristics
  if [ -d "wiki/heuristics" ]; then
    heuristic_count=$(find wiki/heuristics -maxdepth 1 -name "HEU-*.md" -o -name "IRON-*.md" 2>/dev/null | wc -l | tr -d ' ')
  fi

  # Memory server health
  if [ -f "$HOME/.claude/settings.json" ] && command -v jq >/dev/null 2>&1; then
    local mcp_cmd mcp_cwd
    mcp_cmd=$(jq -r '.mcpServers.memory.command // empty' "$HOME/.claude/settings.json" 2>/dev/null || true)
    if [ -n "$mcp_cmd" ]; then
      if [ ! -x "$mcp_cmd" ] && [ ! -f "$mcp_cmd" ]; then
        mem_status="broken (python not found)"
        needs_attention="${needs_attention}memory "
      else
        mcp_cwd=$(jq -r '.mcpServers.memory.cwd // empty' "$HOME/.claude/settings.json" 2>/dev/null || true)
        if ! (cd "$mcp_cwd" 2>/dev/null && "$mcp_cmd" -c "import memory_server" 2>/dev/null); then
          mem_status="broken (import failed)"
          needs_attention="${needs_attention}memory "
        else
          mem_status="healthy"
          local db_path=".memory/memory.db"
          if [ -f "$db_path" ] && command -v sqlite3 >/dev/null 2>&1; then
            local entry_count
            entry_count=$(sqlite3 "$db_path" "SELECT COUNT(*) FROM memories WHERE active = 1;" 2>/dev/null || echo "?")
            mem_status="healthy ($entry_count entries)"
          fi
        fi
      fi
    fi
  fi

  # Memory search guidance
  local mem_query=""
  if [ -f ".dev-wiki/tasks.md" ]; then
    mem_query=$(grep -m1 '^\- \[ \]' ".dev-wiki/tasks.md" 2>/dev/null | sed 's/^- \[ \] \[.\] //' | sed 's/ —.*//' | head -c 80 || true)
  fi

  # Emit structured diagnostic
  echo "[nana:cognitive] Readiness:"
  echo "  enforce: $enforce_status"
  echo "  wiki: $wiki_status"
  echo "  heuristics: $heuristic_count"
  echo "  memory: $mem_status"
  _nana_kit_summary
  if [ -n "$mem_query" ]; then
    echo "  search: memory_search \"$mem_query\""
  fi

  # Recommended actions (needs-attention items)
  if [ -n "$needs_attention" ]; then
    echo "[nana:cognitive] Recommended action:"
    case "$needs_attention" in
      *wiki-empty*)
        echo "  Run /wiki-init then /wiki-bootstrap to set up domain knowledge."
        ;;
      *wiki-domain*)
        echo "  Run /wiki-bootstrap to seed domain articles (heuristics exist but no domain content)."
        ;;
    esac
    case "$needs_attention" in
      *memory*)
        echo "  Run install.sh --status to diagnose memory server."
        ;;
    esac
    case "$needs_attention" in
      *enforce*)
        echo "  Run: touch .claude/enforce to enable spec/loop enforcement."
        ;;
    esac
  fi
}
