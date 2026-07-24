---
name: create
description: Create a new Agent Skill from a short or incomplete request via intent compilation, architecture, deterministic validation, evaluation, and one bounded repair. Use when the user asks Skill Lab to design or generate a Skill.
---

# Create

Create a new Agent Skill as a minimal, valid package. Orchestrate specialist agents and deterministic checks. Do not publish, deploy, bill, delete, or handle credentials.

## Workflow

1. Collect the request (purpose, constraints, known unknowns).
2. Delegate to the `intent-compiler` subagent for a structured contract and assumptions.
3. Route complexity (Level 1 / 2 / 3). See `references/complexity-routing.md`.
4. Delegate to the `skill-architect` subagent for the smallest valid package.
5. Validate:

```bash
"$CLAUDE_PLUGIN_ROOT/bin/skill-lab-validate" <skill-dir>
```

6. Evaluate by level:
   - Level 1: lightweight review + validator evidence
   - Level 2+: isolated `output-evaluator`; run trigger evals if present
7. At most **one** bounded repair iteration for MVP. Re-validate after repair.
8. Select the highest-scoring **valid** checkpoint with `skill-lab-compare`.
9. Write run evidence under `.skill-lab/runs/<run-id>/` (no secrets). See `references/run-artifacts.md`.
10. Report: name, path, files, assumptions, triggers, non-triggers, validation commands, evidence, limitations, best checkpoint.
11. **STOP** before publish, deploy, billing, delete, credential, or permission-changing actions.

## Selection Rule

Hard-gate failures invalidate a checkpoint even if the average score is high. Prefer the best valid checkpoint, not the latest.

## References

- `references/create-workflow.md`
- `references/complexity-routing.md`
- `references/run-artifacts.md`
