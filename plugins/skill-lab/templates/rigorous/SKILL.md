---
name: rigorous
description: Rigorous Agent Skill template for high-risk or high-value workflows with scripts, references, fixtures, and evals.
---

# Example Rigorous Skill

## Purpose

High-value workflow with real-medium verification and strict hard gates.

## Hard gates

- Required checks must pass with evidence.
- Irreversible actions require explicit human approval and are out of scope for autonomous execution.
- Do not claim execution that did not occur.

## Defaults

- Prefer the existing project stack.
- Make the smallest complete change.
- Keep portable instructions separate from host-specific adapters.

## Preferences

- Improve clarity and maintainability after hard gates pass.

## Supporting materials

- Architecture notes: `references/architecture.md`
- Security notes: `references/security.md`
- Validation helper: `scripts/validate.sh`
- Add `evals/` when the skill needs trigger or output evaluation suites
