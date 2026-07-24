# Evaluate workflow

## Resolve target

Normalize to a skill directory containing `SKILL.md`. Do not edit the target.

## Validate package

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-validate" --json <skill-dir>
```

Package validation is a hard gate. Keep the JSON findings even when `passed` is false.

## Validate eval schemas

If `evals/trigger-evals.json` or `evals/output-evals.json` exist:

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --validate-only <skill-dir>
```

This checks JSON shape only. It does not run assertion types such as `contains` / `equals_output`.

## Isolated subjective evaluation

When package validation passed, delegate to `output-evaluator` with read-only inputs (`run_id`, `skill_name`, skill path). It must not modify files. Persist its full JSON under `evaluations/criteria.json`.

When package validation failed, **skip** the evaluator and synthesize criteria from findings (see `evaluate/SKILL.md`). Never call `--aggregate` with `"criteria": []`.

## Aggregate and compare

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --aggregate <criteria.json> --out .skill-lab/runs/<run-id>/scorecard.json
```

Exit code `1` with a written scorecard means hard gates failed—still report it.

Optional:

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-compare" <checkpoints.json>
```

Checkpoints require boolean `hard_gates_passed` (plural). Copy evaluator `recommended_next_action` into the human report; aggregate drops it.

## Evidence

Write `.skill-lab/runs/<run-id>/` and confirm the target Skill was not modified.
