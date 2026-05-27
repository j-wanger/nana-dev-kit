# Active Knowledge — Phase 44

- Heuristic article format requires 6 sections: When this applies, Always, Never, Why, Anti-pattern, Source. YAML frontmatter carries: id, trigger, domain, source_phase, confidence, helpful (counter), harmful (counter), status.
- Transferability test for seed heuristics: "Would this apply to a web app, data pipeline, or CLI tool?" If no, rewrite the trigger to be more general. At least 6/10 must pass.
- Reasoning eval uses LLM-as-judge with 3 dimensions (1-5 each): decision quality (right conclusion), reasoning quality (right tradeoffs considered), anti-pattern avoidance (known failure modes avoided). Judge must score consistently (variance < 0.5 across 3 runs).
- Source material for seed heuristics: .dev-wiki/articles/decisions/ (30+ articles), .claude/rules/working-knowledge.md (60+ entries), specs/ (10+ specs), git log (43 phase commits). Mine for REASONING PATTERNS, not implementation details.
- Knowledge wiki prerequisite: /wiki-init must scaffold wiki/ before heuristic content can be written. "heuristic" must be a recognized category in wiki/schema.md.
