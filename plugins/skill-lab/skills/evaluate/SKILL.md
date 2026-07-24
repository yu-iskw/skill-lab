---
name: evaluate
description: Evaluate an existing Agent Skill for package validity, trigger fit, and output quality without modifying it. Use when the user asks Skill Lab to score or diagnose a Skill.
---

# Evaluate

Evaluate an existing Agent Skill and produce evidence. Do not modify the target Skill.

## Workflow

1. Resolve the skill path to a directory containing `SKILL.md`.
2. Validate the package:

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-validate" --json <skill-dir>
```

If package hard gates fail, **skip** `output-evaluator`, synthesize criteria from validator findings (below), aggregate, and still emit the scorecard.

3. If `evals/trigger-evals.json` or `evals/output-evals.json` exist, validate structure only (MVP does not execute case assertions):

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --validate-only <skill-dir>
```

4. When package validation passed, delegate subjective criteria to the `output-evaluator` subagent in isolation (read/execute only). Pass `run_id`, `skill_name`, skill path, and any eval suite paths.
5. Persist evaluator JSON, then aggregate. `--aggregate` recomputes scores from `criteria[]` and **drops** top-level `summary` / `recommended_next_action`—copy those into the run report yourself:

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --aggregate <criteria.json> --out <scorecard.json>
```

`<criteria.json>` may be the evaluator output or a thin wrapper. `criteria` must be **non-empty**—`--aggregate` rejects `[]` and writes no `--out` file.

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

Each criterion requires: `criterion_id` (string), `score` in `[0,1]`, boolean `passed`, `expected`, `observed`, `evidence` (array), `severity` of `hard|quality|info`.

6. When multiple checkpoints exist:

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-compare" <checkpoints.json>
```

Checkpoints must use boolean **`hard_gates_passed`** (plural). Singular `hard_gate_passed` is rejected.

7. Write scorecard and evidence under `.skill-lab/runs/<run-id>/`.
8. Do not modify the target Skill or its evals.
9. Hard-gate failures cannot be offset by average score. Aggregate exits `1` when hard gates fail; still keep `--out` JSON.

## Hard-fail scorecard synthesis

When validate fails and subjective eval is skipped, build criteria from findings so `--aggregate` is not called with an empty array:

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

Map validator `severity: error` → criterion `severity: hard`.

## Hard Gates

- Missing or invalid `SKILL.md` / frontmatter (including unclosed `---`)
- Name/directory mismatch
- Failed eval structure checks for present evals
- Safety boundary violation
- Any modification of the target during evaluation

## Reference

- `references/evaluate-workflow.md`
