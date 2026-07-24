# Changelog

## 0.1.0 — 2026-07-24

### Added

- Skill Lab Claude Code plugin MVP under `plugins/skill-lab`
- Workflow skills: `create`, `evaluate`
- Subagents: `intent-compiler`, `skill-architect`, `output-evaluator`
- Deterministic CLIs: `skill-lab-validate`, `skill-lab-eval`, `skill-lab-compare` (bash + jq)
- Eval and run schemas under `schemas/`
- Templates: minimal, standard, rigorous
- Fixture Skills: `normalize-config`, `technical-notes-to-article`, `propose-deploy-stop`

### Fixed

- `skill-lab-eval --aggregate` rejects malformed criteria before scoring (score range, boolean `passed`, severity `hard|quality|info`, required fields)
- Shared output-eval validation covers nested assertion/input_files/human_review_points shapes
- Severity vocabulary aligned on RFC `quality` (schemas + fixtures)
- `skill-lab-validate` requires a closing YAML frontmatter `---` delimiter
- Create/evaluate skills document exact CLI argv, hard-fail scorecard synthesis, and structure-only eval suites
- Subagents aligned to CLI contracts: templates by complexity, aggregate handoff fields, `hard_gates_passed` plural, quality→complexity mapping
- Create hard-fail synthesis inlined (map validate `error` → criterion `hard`); checkpoint `overall_score` → `score` mapping documented
- Architect rename checklist + full trigger/output eval required fields; evaluator uses `$CLAUDE_PLUGIN_ROOT/bin` paths only

### Removed

- Sample `hello-world` plugin from the former template repository
