# Run artifacts

Write evidence under `.skill-lab/runs/<run-id>/` with a stable id such as `20260724T125600Z-create-example`.

## Required layout

```text
.skill-lab/runs/<run-id>/
  manifest.json
  evaluations/
    package.json          # skill-lab-validate --json output
    eval-suite.json       # skill-lab-eval --validate-only output (if run)
    criteria.json         # input to --aggregate (evaluator or synthesized)
  scorecard.json          # skill-lab-eval --aggregate --out
  checkpoints/
    index.json            # input to skill-lab-compare
```

## `manifest.json` (MVP minimum)

Align with `schemas/run-manifest.schema.json` when practical. Minimum useful fields:

```json
{
  "run_id": "<run-id>",
  "workflow": "create",
  "skill_name": "<name>",
  "platform": "claude-code",
  "plugin_version": "0.1.0",
  "input_hash": "unknown",
  "eval_suite_hash": "unknown",
  "started_at": "<ISO-8601>",
  "budgets": { "max_iterations": 1 },
  "checkpoints": []
}
```

Use `"unknown"` for hashes when not computed. Copy selected checkpoint metadata into `checkpoints` after compare.

## `scorecard.json`

Prefer the JSON written by `--aggregate --out`. That object uses `hard_gates_passed` (plural) and does not retain evaluator `summary` or `recommended_next_action`—store those under `evaluations/` or the user report.

## Rules

- Generated Skill packages and curated evals may be version-controlled.
- Raw traces should be ignored by default.
- Never persist secrets, tokens, private keys, or raw environment dumps.
- Preserve every checkpoint used for selection.
- Scorecards must cite evidence for every claimed pass.
- `--aggregate` exits `1` when hard gates fail; still keep the written scorecard.
