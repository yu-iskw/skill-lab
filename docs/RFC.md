# RFC: Skill Lab — Design Summary

> Status: Adopted for MVP implementation  
> Repository: `yu-iskw/skill-lab`  
> Date: 2026-07-24

## Decision

Skill Lab is a Claude Code plugin composed of:

1. **Interaction plane** — user-facing workflow skills (`create`, `evaluate`; improve/diagnose/extract later)
2. **Orchestration plane** — complexity routing, budgets, approval gates, run state
3. **Reasoning plane** — isolated subagents (`intent-compiler`, `skill-architect`, `output-evaluator`; more later)
4. **Verification plane** — deterministic validators and score/checkpoint selection (`bash` + `jq`)
5. **Artifact plane** — portable Skill packages, eval suites, run evidence, reports

Generated Skills conform to the portable Agent Skills specification by default. Claude Code-specific behavior remains in the plugin/adapter layer.

## MVP

- `/skill-lab:create` and `/skill-lab:evaluate`
- Three subagents listed above
- Package validation + trigger/output eval schemas
- One bounded repair iteration
- Best-valid-checkpoint selection
- Three fixture Skills

## Non-goals (MVP)

Hosted registry, autonomous publish/deploy, Codex adapter, hooks behavior, unbounded improvement loops, treating LLM judgment as ground truth.

## Hard gates for Skill Lab

Skill Lab fails validation if it claims completion without evidence, lets hard failures be offset by average score, allows evaluators to mutate the target, selects an invalid checkpoint when a valid one exists, or performs irreversible actions without approval.

Full scenario review checklist lives in the project RFC discussion (2026-07-24).
