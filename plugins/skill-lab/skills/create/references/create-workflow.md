# Create workflow

Expands the `create` skill. Keep `SKILL.md` short; use this for phase detail.

## Phase 1 — Collect

Capture raw request, optional skill name, audience, constraints, and known unknowns. Ask follow-ups only when missing information would make the skill unsafe or unusable.

## Phase 2 — Compile intent

Delegate to `intent-compiler`. Treat the compiled contract as the working spec.

## Phase 3 — Route complexity

Use `complexity-routing.md`. If uncertain, choose the higher level. Level 3 means slow down or stop at unsafe boundaries.

## Phase 4 — Architect

Delegate to `skill-architect` for the smallest valid package that satisfies the contract. Prefer `SKILL.md` only; add references/scripts/evals only when justified.

## Phase 5 — Validate

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-validate" <skill-dir>
```

Validation is a hard gate. Invalid checkpoints cannot be selected.

## Phase 6 — Evaluate

- Level 1: lightweight review + deterministic checks + trigger evals if present
- Level 2+: isolated `output-evaluator` + `skill-lab-eval`

## Phase 7 — Bounded repair (MVP: one iteration)

Repair only validator or evaluation failures. Re-run validation and evaluation. Do not start a second repair loop.

## Phase 8 — Select best valid checkpoint

Use `skill-lab-compare`. Exclude invalid and hard-gate failures. Highest score wins; ties prefer smaller package, then earlier checkpoint.

## Phase 9 — Evidence and report

Write `.skill-lab/runs/<run-id>/` per `run-artifacts.md`. Report name, path, files, assumptions, triggers, non-triggers, commands, evidence, limitations, best checkpoint.

## Stop boundaries

Stop before publishing, deploying, billing changes, deletion, credential handling, or permission changes.
