# Run artifacts

Write evidence under `.skill-lab/runs/<run-id>/` with a stable id such as `20260724T125600Z-create-example`.

## Required files

```text
.skill-lab/runs/<run-id>/
  manifest.json
  evaluations/
  scorecard.json
  checkpoints/
```

## Rules

- Generated Skill packages and curated evals may be version-controlled.
- Raw traces should be ignored by default.
- Never persist secrets, tokens, private keys, or raw environment dumps.
- Preserve every checkpoint used for selection.
- Scorecards must cite evidence for every claimed pass.
