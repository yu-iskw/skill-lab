# docs/contracts

Frozen contracts for Skill Lab (`schema_version` **1.0.0**).

**Source of truth:** this directory. Plugin consumers MUST reference these files via symlink or a CI identity check (`diff` against `plugins/skill-lab/schemas/`). Do not maintain an unsynced copy.

| Schema                                  | Purpose                          | MVP?                                 |
| --------------------------------------- | -------------------------------- | ------------------------------------ |
| `schemas/common.schema.json`            | Shared `$defs`                   | yes                                  |
| `schemas/skill-state.schema.json`       | Intent compiler contract         | yes                                  |
| `schemas/run-manifest.schema.json`      | Per-run metadata and checkpoints | yes                                  |
| `schemas/evaluation-result.schema.json` | Aggregated criterion results     | yes                                  |
| `schemas/output-eval.schema.json`       | Output evaluation suites         | yes                                  |
| `schemas/trigger-eval.schema.json`      | Trigger suites                   | **post-MVP** (frozen forward-compat) |

Breaking changes require ADR 0001 gates (≥20 fixtures across ≥3 fixture Skills + version bump).
