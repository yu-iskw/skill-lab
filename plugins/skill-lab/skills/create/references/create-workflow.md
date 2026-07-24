# Create workflow

Expands the `create` skill. Keep `SKILL.md` short; use this for phase detail.

## Phase 1 — Collect

Capture raw request, optional skill name, audience, constraints, write root, and known unknowns. Ask follow-ups only when missing information would make the skill unsafe or unusable.

Default write root: current workspace. Package path: `<write-root>/<kebab-case-name>/`.

## Phase 2 — Compile intent

Delegate to `intent-compiler`. Treat the compiled contract as the working spec. Honor `suggested_complexity_level` and `suggested_template` unless routing rules force Level 3.

## Phase 3 — Route complexity

Use `complexity-routing.md`. If uncertain, choose the higher level. Level 3 means slow down or stop at unsafe boundaries—do not implement credential/billing/delete/deploy/permission automation. Exception: when the user explicitly wants a documentation-only plan-and-stop Skill (fixture `propose-deploy-stop`), continue with architect using the rigorous template.

## Phase 4 — Architect

Delegate to `skill-architect` with contract, complexity level, write root, and `$CLAUDE_PLUGIN_ROOT`. Architect copies from `templates/{minimal,standard,rigorous}/` by level, renames the package, and writes the smallest valid package that satisfies the contract.

## Phase 5 — Validate

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-validate" --json <skill-dir>
```

Validation is a hard gate. Invalid checkpoints cannot be selected. Prefer `--json` and capture stdout even when exit code is `1`. On failure—or when folding findings into Level 1 criteria—use create `SKILL.md` **Finding severity map** (`error`→`hard`, `warning`→`quality`). Never pass validate's `error`/`warning` strings to aggregate.

## Phase 6 — Evaluate and scorecard

MVP eval suites are **structure-validated only** (no assertion execution). Only `evals/trigger-evals.json` and `evals/output-evals.json` are checked.

```bash
# When canonical eval files exist (any level)
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --validate-only <skill-dir>
```

Build a **non-empty** `criteria.json`, then always aggregate:

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --aggregate <criteria.json> --out <scorecard.json>
```

Keep `--out` even when exit code is `1`.

- Level 1 (valid package): lightweight review + deterministic checks (+ structure-validate evals if present). Optional short `output-evaluator` pass to author criteria.
- Level 2+ (valid package): isolated `output-evaluator` authors criteria.
- Invalid package (any level): synthesize criteria from validate findings; skip `output-evaluator`; still run `--aggregate --out`.

Criteria must use severity `hard|quality|info` and boolean `passed`. Include `run_id` and `skill_name`. Never pass `"criteria": []`.

## Phase 7 — Bounded repair (MVP: one iteration)

Repair only validator or evaluation failures. Re-run validation and evaluation. Do not start a second repair loop.

## Phase 8 — Select best valid checkpoint

Build `checkpoints.json` from the scorecard. Map `overall_score` → `score`. Do **not** pass `scorecard.json` to compare.

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-compare" <checkpoints.json>
```

Each checkpoint: `id`, numeric `score`, boolean `hard_gates_passed` (plural). Exclude invalid and hard-gate failures. Highest score wins; ties prefer smaller `file_count`, then earlier `created_at`, then `id`.

## Phase 9 — Evidence and report

Write `.skill-lab/runs/<run-id>/` per `run-artifacts.md`. Preserve evaluator `recommended_next_action` in the human report—`--aggregate` drops it. Report name, path, files, assumptions, triggers, non-triggers, commands, evidence, limitations, best checkpoint.

## Stop boundaries

Stop before publishing, deploying, billing changes, deletion, credential handling, or permission changes.
