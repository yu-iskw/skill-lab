---
name: evaluate
description: Evaluate an existing Agent Skill for package validity, trigger fit, and output quality without modifying it. Use when the user asks Skill Lab to score or diagnose a Skill.
---

# Evaluate

Evaluate an existing Agent Skill and produce evidence. Do not modify the target Skill.

## Workflow

1. Resolve the skill path to a directory containing `SKILL.md`.
2. Validate the package with `"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-validate" <skill-dir>`. If package hard gates fail, skip subjective evaluation and still emit the scorecard.
3. If eval files exist, validate them with `"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --validate-only <skill-dir>`.
4. Delegate subjective criteria to the `output-evaluator` subagent in isolation (read/execute only).
5. Aggregate results with `"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-eval" --aggregate`; use `"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-compare"` when multiple checkpoints exist.
6. Write scorecard and evidence under `.skill-lab/runs/<run-id>/`.
7. Do not modify the target Skill or its evals.
8. Hard-gate failures cannot be offset by average score.

## Hard Gates

- Missing or invalid `SKILL.md` / frontmatter
- Name/directory mismatch
- Failed schema validation for present evals
- Safety boundary violation
- Any modification of the target during evaluation

## Reference

- `references/evaluate-workflow.md`
