---
name: create
description: Create a new Agent Skill from a short or incomplete request via intent compilation, architecture, deterministic validation, evaluation, and one bounded repair. Use when the user asks Skill Lab to design or generate a Skill.
---

# Create

Create a new Agent Skill as a minimal, valid package. Orchestrate specialist agents and deterministic checks. Do not publish, deploy, bill, delete, or handle credentials.

## Workflow

1. Collect the request (purpose, constraints, known unknowns). Choose a write root (default: current workspace). The package directory must be kebab-case and match frontmatter `name`.
2. Delegate to the `intent-compiler` subagent for a structured contract and assumptions.
3. Route complexity (Level 1 / 2 / 3) using `references/complexity-routing.md`. Map intent `quality_level` as documented there. If Level 3 requires an unsafe action: **STOP** unless the user explicitly wants a documentation-only plan-and-stop Skill (see fixture `propose-deploy-stop`). Never architect a Skill that executes credentials, billing, delete, deploy, or permission changes.
4. Delegate to the `skill-architect` subagent. Pass the contract, complexity level, write root, and `$CLAUDE_PLUGIN_ROOT`. Architect starts from `templates/{minimal,standard,rigorous}/` by level.
5. Validate (hard gate) with `"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-validate" --json <skill-dir>`. Capture stdout even when exit code is `1`. If package hard gates fail, skip subjective evaluation, synthesize criteria (see **Hard-fail scorecard synthesis**), then still aggregate to a scorecard.
6. Build evaluation criteria by level (see **Evaluate by level**), then always produce a scorecard with `"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --aggregate <criteria.json> --out <scorecard.json>`. Prefer `--out`; keep that file even when exit code is `1`.
7. At most **one** bounded repair iteration for MVP. Re-validate after repair.
8. Build `checkpoints.json` by mapping scorecard `overall_score` → checkpoint `score` (see **Checkpoint payload**), then select with `"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-compare" <checkpoints.json>`. Do not pass the scorecard file to compare.
9. Write run evidence under `.skill-lab/runs/<run-id>/` (no secrets). See `references/run-artifacts.md`.
10. Report: name, path, files, assumptions, triggers, non-triggers, validation commands, evidence, limitations, best checkpoint.
11. **STOP** before publish, deploy, billing, delete, credential, or permission-changing actions.

## Evaluate by level

- **All levels:** if `evals/trigger-evals.json` or `evals/output-evals.json` exist, structure-validate only with `"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --validate-only <skill-dir>`. Other filenames under `evals/` are ignored by the CLIs. MVP does not execute assertion runners.
- **Level 1 (package valid):** build a short non-empty criteria list from validator evidence plus lightweight review of description, triggers/non-triggers, and hard gates in `SKILL.md`. Optional: ask `output-evaluator` for that criteria list.
- **Level 2+ (package valid):** delegate to isolated `output-evaluator` for the criteria list.
- **Any level (package invalid):** use synthesized findings criteria; do not call `output-evaluator`.

`<criteria.json>` must include `run_id`, `skill_name`, and a **non-empty** `criteria` array. Use field name **`hard_gates_passed`** (plural) everywhere. Severity vocabulary is **`hard|quality|info`** only.

## Finding severity map

`skill-lab-validate` findings use `error` / `warning`. `--aggregate` rejects those strings. Always remap before building criteria (including Level 1 “validator evidence” on **passing** packages that still emit warnings such as `FORBIDDEN_PLACEHOLDER`):

| Validate finding `severity` | Criterion `severity` | Typical `passed` |
| --------------------------- | -------------------- | ---------------- |
| `error`                     | `hard`               | `false`          |
| `warning`                   | `quality`            | `false`          |

Never copy `"error"`, `"warning"`, or `"soft"` into criteria.

## Hard-fail scorecard synthesis

When validate fails (`passed: false`), map **every** finding through the table above (not only errors). Example after remapping an `error` finding:

```json
{
  "run_id": "<run-id>",
  "skill_name": "<name-or-dir>",
  "criteria": [
    {
      "criterion_id": "<finding.code>",
      "score": 0,
      "passed": false,
      "expected": "package validation passes",
      "observed": "<finding.message>",
      "evidence": ["<finding.code>"],
      "severity": "hard"
    }
  ],
  "remaining_human_review_points": [
    "Fix package hard gates before subjective evaluation"
  ]
}
```

## Checkpoint payload

Compare requires a checkpoints file, not the scorecard. Map `overall_score` → `score`:

```json
{
  "checkpoints": [
    {
      "id": "c0",
      "path": "<skill-dir>",
      "score": 0.9,
      "hard_gates_passed": true,
      "file_count": 2,
      "created_at": "2026-07-24T21:00:00Z"
    }
  ]
}
```

Each checkpoint needs `id`, numeric `score`, and boolean `hard_gates_passed`. Invalid/high-scoring checkpoints must not win.

## Selection Rule

Hard-gate failures invalidate a checkpoint even if the average score is high. Prefer the best valid checkpoint, not the latest. `--aggregate` exits `1` when `hard_gates_passed` is false—still keep the JSON (prefer `--out`).

## References

- `references/create-workflow.md`
- `references/complexity-routing.md`
- `references/run-artifacts.md`
