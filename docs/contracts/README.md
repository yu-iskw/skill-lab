# docs/contracts

Frozen MVP contracts for Skill Lab (`schema_version` **1.0.0**).

| Schema | Purpose |
| --- | --- |
| `schemas/trigger-eval.schema.json` | Trigger evaluation suites |
| `schemas/output-eval.schema.json` | Output evaluation suites |
| `schemas/evaluation-result.schema.json` | Aggregated criterion results |
| `schemas/run-manifest.schema.json` | Per-run metadata and checkpoints |
| `schemas/skill-state.schema.json` | Intent compiler contract |

Breaking changes require ADR 0001 gates (≥20 fixtures across ≥3 fixture Skills + version bump).
