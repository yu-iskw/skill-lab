---
name: evaluate
description: Evaluate an existing Agent Skill for package validity, trigger fit, and output quality without modifying it. Use when the user asks Skill Lab to score or diagnose a Skill.
---

# Evaluate

Evaluate an existing Agent Skill and produce evidence. Do not modify the target Skill.

## Workflow

1. Resolve the skill path to a directory containing `SKILL.md`.
2. Validate the package with `"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-validate" --json <skill-dir>`. Capture stdout even when exit code is `1`. If package hard gates fail, **skip** `output-evaluator`, synthesize criteria from validator findings (below), aggregate, and still emit the scorecard.
3. If `evals/trigger-evals.json` or `evals/output-evals.json` exist, structure-validate only with `"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --validate-only <skill-dir>` (MVP does not execute case assertions). Other `evals/*.json` names are ignored.
4. When package validation passed, delegate subjective criteria to the `output-evaluator` subagent in isolation (read/execute only). Pass `run_id`, `skill_name`, skill path, and any eval suite paths.
5. Persist evaluator JSON, then aggregate with `"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --aggregate <criteria.json> --out <scorecard.json>`. Prefer `--out` and keep that file even when exit code is `1`. `--aggregate` recomputes scores from `criteria[]` and **drops** top-level `summary` / `recommended_next_action`—copy those into the run report yourself. `criteria` must be **non-empty**. Each criterion requires: `criterion_id` (string), `score` in `[0,1]`, boolean `passed`, `expected`, `observed`, `evidence` (array), `severity` of `hard|quality|info`. Remap validate findings first (`error`→`hard`, `warning`→`quality`); never copy `error`/`warning`/`soft` into criteria.
6. When multiple checkpoints exist, build a checkpoints file (map scorecard `overall_score` → checkpoint `score`; never pass the scorecard to compare), then run `"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-compare" <checkpoints.json>`. Checkpoints must use boolean **`hard_gates_passed`** (plural).
7. Write scorecard and evidence under `.skill-lab/runs/<run-id>/`.
8. Do not modify the target Skill or its evals.
9. Hard-gate failures cannot be offset by average score. Aggregate exits `1` when hard gates fail; still keep `--out` JSON.

## Criteria wrapper example

```json
{
  "run_id": "<run-id>",
  "skill_name": "<name>",
  "criteria": [
    {
      "criterion_id": "PKG1",
      "score": 1.0,
      "passed": true,
      "expected": "package validation passes",
      "observed": "skill-lab-validate passed=true",
      "evidence": ["evaluations/package.json"],
      "severity": "hard"
    }
  ],
  "remaining_human_review_points": []
}
```

## Finding severity map

Validate findings use `error` / `warning`; aggregate accepts only `hard|quality|info`:

| Validate finding `severity` | Criterion `severity` | Typical `passed` |
| --------------------------- | -------------------- | ---------------- |
| `error`                     | `hard`               | `false`          |
| `warning`                   | `quality`            | `false`          |

Warnings can appear on **passing** packages (for example `FORBIDDEN_PLACEHOLDER` for `TODO`/`FIXME`/`TBD`/`<[A-Z_]+>`). Remap them before aggregate or the scorecard write fails.

## Hard-fail scorecard synthesis

When validate fails and subjective eval is skipped, build criteria from **all** findings so `--aggregate` is not called with an empty array. Remap severities with the table above:

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

## Hard Gates

- Missing or invalid `SKILL.md` / frontmatter (including unclosed `---`)
- Name/directory mismatch
- Failed eval structure checks for present evals
- Safety boundary violation
- Any modification of the target during evaluation

## Reference

- `references/evaluate-workflow.md`
