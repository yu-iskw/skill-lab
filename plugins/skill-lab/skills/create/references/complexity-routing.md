# Complexity routing

Use the lowest level that safely covers the request. If unsure, route higher.

| Level | Signals                                             | Required handling                                  | Template   |
| ----- | --------------------------------------------------- | -------------------------------------------------- | ---------- |
| 1     | Single SKILL.md, clear trigger, no external effects | Intent, architect, validator, lightweight evaluation | `minimal`  |
| 2     | Multi-step workflow, scripts, ambiguous criteria    | Plus isolated `output-evaluator`, eval aggregation | `standard` |
| 3     | Credentials, billing, deletion, deployment, blast radius | Stop at unsafe boundary; require human direction | `rigorous` |

## Intent `quality_level` mapping

| Intent `quality_level` | Default level | Override |
| ---------------------- | ------------- | -------- |
| `prototype` | 1 | Raise if scripts/evals/ambiguity appear |
| `mvp` | 2 | Raise to 3 on unsafe actions |
| `production` | 2 | Raise to 3 on unsafe actions |

Intent-compiler may emit `suggested_complexity_level` and `suggested_template`; still apply the Level 3 safety rule.

## Rules

- Any credential, billing, delete, deploy, or permission-changing action is Level 3.
- Level 3 does not authorize the action. Architect may produce a plan-and-stop Skill only when that is the explicit request (see fixture `propose-deploy-stop`).
- Failed deterministic validation is always a hard gate.
- MVP repair limit is one iteration.
- Present eval suites are structure-validated at every level; assertion execution is out of MVP scope.
