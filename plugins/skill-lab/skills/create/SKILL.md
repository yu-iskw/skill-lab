---
name: create
description: Create a new Agent Skill from a short or incomplete request via intent compilation, architecture, deterministic validation, evaluation, and one bounded repair. Use when the user asks Skill Lab to design or generate a Skill.
---

# Create

Create a new Agent Skill as a minimal, valid package. Orchestrate specialist agents and deterministic checks. Do not publish, deploy, bill, delete, or handle credentials.

## Workflow

1. Collect the request (purpose, constraints, known unknowns). Choose a write root (default: current workspace). The package directory must be kebab-case and match frontmatter `name`.
2. Delegate to the `intent-compiler` subagent for a structured contract and assumptions.
3. Route complexity (Level 1 / 2 / 3) using `references/complexity-routing.md`. Map intent `quality_level` as documented there. If Level 3 and the request requires an unsafe action, **STOP** and ask for human direction—do not architect a Skill that performs the action.
4. Delegate to the `skill-architect` subagent. Pass the contract, complexity level, write root, and `$CLAUDE_PLUGIN_ROOT`. Architect starts from `templates/{minimal,standard,rigorous}/` by level.
5. Validate (hard gate):

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-validate" --json <skill-dir>
```

If package hard gates fail, skip subjective evaluation, synthesize criteria from findings (same shape as evaluate skill hard-fail synthesis), then still aggregate to a scorecard (step 6c) and write evidence.

6. Evaluate by level, then always produce a scorecard via `--aggregate`:
   - **All levels:** if `evals/*.json` exist, run structure validation only (MVP does not execute assertion runners):

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --validate-only <skill-dir>
```

- **Level 1 (package valid):** build a short non-empty criteria list from validator evidence plus lightweight review of description, triggers/non-triggers, and hard gates in `SKILL.md`. Optional: ask `output-evaluator` for that criteria list.
- **Level 2+ (package valid):** delegate to isolated `output-evaluator` for the criteria list.
- **Any level (package invalid):** use synthesized findings criteria; do not call `output-evaluator`.
- **All levels — aggregate:**

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --aggregate <criteria.json> --out <scorecard.json>
```

`<criteria.json>` must include `run_id`, `skill_name`, and a **non-empty** `criteria` array. Use field name **`hard_gates_passed`** (plural) everywhere. Severity vocabulary is **`hard|quality|info`** (not `soft`).

7. At most **one** bounded repair iteration for MVP. Re-validate after repair.
8. Select the highest-scoring **valid** checkpoint:

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-compare" <checkpoints.json>
```

Each checkpoint needs `id`, numeric `score`, and boolean `hard_gates_passed`. Invalid/high-scoring checkpoints must not win.

9. Write run evidence under `.skill-lab/runs/<run-id>/` (no secrets). See `references/run-artifacts.md`.
10. Report: name, path, files, assumptions, triggers, non-triggers, validation commands, evidence, limitations, best checkpoint.
11. **STOP** before publish, deploy, billing, delete, credential, or permission-changing actions.

## Selection Rule

Hard-gate failures invalidate a checkpoint even if the average score is high. Prefer the best valid checkpoint, not the latest. `--aggregate` exits `1` when `hard_gates_passed` is false—still keep the JSON (prefer `--out`).

## References

- `references/create-workflow.md`
- `references/complexity-routing.md`
- `references/run-artifacts.md`
