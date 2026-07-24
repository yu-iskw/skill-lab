# Evaluate workflow

## Resolve target

Normalize to a skill directory containing `SKILL.md`. Do not edit the target.

## Validate package

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-validate" <skill-dir>
```

Package validation is a hard gate.

## Validate eval schemas

If `evals/trigger-evals.json` or `evals/output-evals.json` exist:

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --validate-only <skill-dir>
```

## Isolated subjective evaluation

Delegate to `output-evaluator` with read-only inputs. It must not modify files.

## Aggregate and report

Aggregate deterministic and subjective results. Hard-gate failures invalidate the result regardless of average score. Write evidence under `.skill-lab/runs/<run-id>/` and confirm the target was not modified.
